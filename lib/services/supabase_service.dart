// lib/services/supabase_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../config/app_config.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;

  // FIX: Safe uid getter — throws a clear error instead of null-crash
  // if called while the user is signed out (e.g. token expiry mid-session).
  static String get _uid {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');
    return uid;
  }

  // ─── AUTH ───────────────────────────────────────────────

  static Future<void> signInWithEmail(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static User? get currentUser => _client.auth.currentUser;

  static Stream<AuthState> get authStateStream => _client.auth.onAuthStateChange;

  // ─── PROFILES ───────────────────────────────────────────

  static Future<UserProfile?> getProfile(String userId) async {
    try {
      final res = await _client.from('profiles').select().eq('id', userId).maybeSingle();
      return res != null ? UserProfile.fromJson(res) : null;
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  static Future<List<UserProfile>> getPendingUsers() async {
    try {
      final res = await _client
          .from('profiles')
          .select()
          .eq('access_status', 'pending')
          .order('requested_at', ascending: true);
      return res.map((e) => UserProfile.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load pending users: $e');
    }
  }

  static Future<List<UserProfile>> getApprovedUsers() async {
    try {
      final res = await _client
          .from('profiles')
          .select()
          .eq('access_status', 'approved')
          .order('full_name', ascending: true);
      return res.map((e) => UserProfile.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load approved users: $e');
    }
  }

  static Future<void> approveUser(String userId) async {
    try {
      await _client.from('profiles').update({
        'access_status': 'approved',
        'approved_at': DateTime.now().toIso8601String(),
        'approved_by': _uid,
      }).eq('id', userId);
      await _client.from('notifications').insert({
        'user_id': userId,
        'title': 'Access approved!',
        'body': 'You can now access NirmanApp. Welcome aboard!',
        'type': 'access_approved',
      });
    } catch (e) {
      throw Exception('Failed to approve user: $e');
    }
  }

  static Future<void> rejectUser(String userId) async {
    try {
      await _client.from('profiles').update({
        'access_status': 'rejected',
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to reject user: $e');
    }
  }

  static Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _client.from('profiles').update(data).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // ─── PROJECTS ───────────────────────────────────────────

  static Future<List<Project>> getProjects() async {
    try {
      final res = await _client.from('project_summary').select().order('created_at', ascending: false);
      return res.map((e) => Project.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load projects: $e');
    }
  }

  static Future<Project?> getProject(String projectId) async {
    try {
      final res = await _client.from('project_summary').select().eq('id', projectId).maybeSingle();
      return res != null ? Project.fromJson(res) : null;
    } catch (e) {
      throw Exception('Failed to load project: $e');
    }
  }

  static Future<Project> createProject(Map<String, dynamic> data) async {
    try {
      final res = await _client.from('projects').insert({
        ...data,
        'owner_id': _uid,
      }).select().single();
      await _client.from('project_members').insert({
        'project_id': res['id'],
        'user_id': _uid,
        'role': 'admin',
      });
      // FIX: _createDefaultPhases now uses batch inserts to avoid N+1 queries
      await _createDefaultPhases(res['id']);
      return Project.fromJson(res);
    } catch (e) {
      throw Exception('Failed to create project: $e');
    }
  }

  // FIX: Batch-insert phases in one call, then batch-insert planning items
  // in one call. Previously this looped with individual awaits = N+1 problem
  // that fired dozens of DB requests and caused visible startup lag.
  static Future<void> _createDefaultPhases(String projectId) async {
    final templates = await _client.from('phase_templates').select().order('order_index');
    if (templates.isEmpty) return;

    // Batch insert all phases at once
    final phaseInserts = templates.map((t) => {
      'project_id': projectId,
      'name': t['name'],
      'order_index': t['order_index'],
      'color': t['color'],
      'status': 'upcoming',
    }).toList();

    final phases = await _client.from('phases').insert(phaseInserts).select();

    // Find planning phase
    final planningPhase = phases.cast<Map<String, dynamic>>().where(
      (p) => (p['name'] as String).toLowerCase().contains('planning')
    ).firstOrNull;

    if (planningPhase == null) return;

    final itemTemplates = await _client.from('planning_item_templates').select().order('order_index');
    if (itemTemplates.isEmpty) return;

    // Batch insert all planning items at once
    final itemInserts = itemTemplates.map((it) => {
      'project_id': projectId,
      'phase_id': planningPhase['id'],
      'name': it['name'],
      'item_type': it['item_type'],
      'order_index': it['order_index'],
      'status': 'todo',
    }).toList();

    await _client.from('planning_items').insert(itemInserts);
  }

  static Future<void> updateProject(String projectId, Map<String, dynamic> data) async {
    try {
      await _client.from('projects').update(data).eq('id', projectId);
    } catch (e) {
      throw Exception('Failed to update project: $e');
    }
  }

  // ─── PROJECT MEMBERS ────────────────────────────────────

  static Future<List<ProjectMember>> getProjectMembers(String projectId) async {
    try {
      final res = await _client.from('project_members').select('*, profiles(*)').eq('project_id', projectId);
      return res.map((e) => ProjectMember.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load project members: $e');
    }
  }

  static Future<void> addProjectMember(String projectId, String userId, String role) async {
    try {
      await _client.from('project_members').upsert({
        'project_id': projectId,
        'user_id': userId,
        'role': role,
        'invited_by': _uid,
      });
    } catch (e) {
      throw Exception('Failed to add project member: $e');
    }
  }

  // ─── PHASES ─────────────────────────────────────────────

  static Future<List<Phase>> getPhases(String projectId) async {
    try {
      final res = await _client.from('phase_progress').select().eq('project_id', projectId).order('order_index');
      return res.map((e) => Phase.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load phases: $e');
    }
  }

  static Future<Phase> createPhase(Map<String, dynamic> data) async {
    try {
      final res = await _client.from('phases').insert(data).select().single();
      return Phase.fromJson(res);
    } catch (e) {
      throw Exception('Failed to create phase: $e');
    }
  }

  static Future<void> updatePhase(String phaseId, Map<String, dynamic> data) async {
    try {
      await _client.from('phases').update(data).eq('id', phaseId);
    } catch (e) {
      throw Exception('Failed to update phase: $e');
    }
  }

  // ─── PLANNING ITEMS ─────────────────────────────────────

  static Future<List<PlanningItem>> getPlanningItems(String projectId) async {
    try {
      final res = await _client.from('planning_items').select().eq('project_id', projectId).order('order_index');
      return res.map((e) => PlanningItem.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load planning items: $e');
    }
  }

  static Future<void> updatePlanningItem(String id, Map<String, dynamic> data) async {
    try {
      await _client.from('planning_items').update(data).eq('id', id);
    } catch (e) {
      throw Exception('Failed to update planning item: $e');
    }
  }

  // ─── TASKS ──────────────────────────────────────────────

  static Future<List<Task>> getTasks(String projectId, {String? status, String? phaseId}) async {
    try {
      var query = _client.from('tasks').select().eq('project_id', projectId);
      if (status != null) query = query.eq('status', status);
      if (phaseId != null) query = query.eq('phase_id', phaseId);
      final res = await query.order('due_date', ascending: true);
      return res.map((e) => Task.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load tasks: $e');
    }
  }

  static Future<Task> createTask(Map<String, dynamic> data) async {
    try {
      final res = await _client.from('tasks').insert({...data, 'created_by': _uid}).select().single();
      return Task.fromJson(res);
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  static Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    try {
      await _client.from('tasks').update(data).eq('id', taskId);
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  static Future<void> deleteTask(String taskId) async {
    try {
      await _client.from('tasks').delete().eq('id', taskId);
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  // ─── ISSUES ─────────────────────────────────────────────

  static Future<List<Issue>> getIssues(String projectId, {String? status}) async {
    try {
      var query = _client.from('issues').select().eq('project_id', projectId);
      if (status != null) query = query.eq('status', status);
      final res = await query.order('created_at', ascending: false);
      return res.map((e) => Issue.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load issues: $e');
    }
  }

  static Future<Issue> createIssue(Map<String, dynamic> data) async {
    try {
      final res = await _client.from('issues').insert({...data, 'reported_by': _uid}).select().single();
      return Issue.fromJson(res);
    } catch (e) {
      throw Exception('Failed to create issue: $e');
    }
  }

  static Future<void> updateIssue(String issueId, Map<String, dynamic> data) async {
    try {
      await _client.from('issues').update(data).eq('id', issueId);
    } catch (e) {
      throw Exception('Failed to update issue: $e');
    }
  }

  // ─── DAILY LOGS ─────────────────────────────────────────

  static Future<List<DailyLog>> getDailyLogs(String projectId, {int limit = 30}) async {
    try {
      final res = await _client.from('daily_logs').select().eq('project_id', projectId)
          .order('log_date', ascending: false).limit(limit);
      return res.map((e) => DailyLog.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load daily logs: $e');
    }
  }

  static Future<DailyLog?> getTodayLog(String projectId) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final res = await _client.from('daily_logs').select().eq('project_id', projectId)
          .eq('log_date', today).maybeSingle();
      return res != null ? DailyLog.fromJson(res) : null;
    } catch (e) {
      throw Exception('Failed to load today\'s log: $e');
    }
  }

  static Future<DailyLog> upsertDailyLog(Map<String, dynamic> data) async {
    try {
      final res = await _client.from('daily_logs').upsert(
          {...data, 'logged_by': _uid}, onConflict: 'project_id,log_date').select().single();
      return DailyLog.fromJson(res);
    } catch (e) {
      throw Exception('Failed to save daily log: $e');
    }
  }

  // ─── CONTRACTORS ────────────────────────────────────────

  static Future<List<Contractor>> getContractors(String projectId) async {
    try {
      final res = await _client.from('contractors').select().eq('project_id', projectId).order('name');
      return res.map((e) => Contractor.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load contractors: $e');
    }
  }

  static Future<Contractor> createContractor(Map<String, dynamic> data) async {
    try {
      final res = await _client.from('contractors').insert(data).select().single();
      return Contractor.fromJson(res);
    } catch (e) {
      throw Exception('Failed to create contractor: $e');
    }
  }

  static Future<void> updateContractor(String id, Map<String, dynamic> data) async {
    try {
      await _client.from('contractors').update(data).eq('id', id);
    } catch (e) {
      throw Exception('Failed to update contractor: $e');
    }
  }

  // ─── MATERIALS ──────────────────────────────────────────

  static Future<List<Material>> getMaterials(String projectId) async {
    try {
      final res = await _client.from('materials').select().eq('project_id', projectId)
          .order('delivery_date', ascending: false);
      return res.map((e) => Material.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load materials: $e');
    }
  }

  static Future<Material> createMaterial(Map<String, dynamic> data) async {
    try {
      final res = await _client.from('materials').insert(data).select().single();
      return Material.fromJson(res);
    } catch (e) {
      throw Exception('Failed to create material: $e');
    }
  }

  // ─── EXPENSES ───────────────────────────────────────────

  static Future<List<Expense>> getExpenses(String projectId, {String? category}) async {
    try {
      var query = _client.from('expenses').select().eq('project_id', projectId);
      if (category != null) query = query.eq('category', category);
      final res = await query.order('expense_date', ascending: false);
      return res.map((e) => Expense.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load expenses: $e');
    }
  }

  static Future<Expense> createExpense(Map<String, dynamic> data) async {
    try {
      final res = await _client.from('expenses').insert({...data, 'paid_by': _uid}).select().single();
      return Expense.fromJson(res);
    } catch (e) {
      throw Exception('Failed to create expense: $e');
    }
  }

  // FIX: getExpenseSummary now uses a server-side aggregate via RPC instead of
  // fetching all rows client-side and summing in Dart. This moves computation
  // to the DB and reduces data transfer.
  // NOTE: If the 'get_expense_summary' RPC doesn't exist yet, falls back
  // to the old client-side method gracefully.
  static Future<Map<String, int>> getExpenseSummary(String projectId) async {
    try {
      final res = await _client.rpc('get_expense_summary', params: {'p_project_id': projectId});
      final Map<String, int> summary = {};
      for (final e in (res as List)) {
        summary[e['category'] as String] = (e['total'] as num).toInt();
      }
      return summary;
    } catch (_) {
      // Fallback: client-side aggregation if RPC not available
      final res = await _client.from('expenses')
          .select('category, amount_paise, gst_paise')
          .eq('project_id', projectId);
      final Map<String, int> summary = {};
      for (final e in res) {
        final cat = e['category'] as String;
        final total = (e['amount_paise'] as int) + (e['gst_paise'] as int);
        summary[cat] = (summary[cat] ?? 0) + total;
      }
      return summary;
    }
  }

  // ─── PAYMENTS ───────────────────────────────────────────

  static Future<List<Payment>> getPayments(String projectId) async {
    try {
      final res = await _client.from('payments').select().eq('project_id', projectId)
          .order('due_date', ascending: true);
      return res.map((e) => Payment.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load payments: $e');
    }
  }

  static Future<Payment> createPayment(Map<String, dynamic> data) async {
    try {
      final res = await _client.from('payments').insert(data).select().single();
      return Payment.fromJson(res);
    } catch (e) {
      throw Exception('Failed to create payment: $e');
    }
  }

  static Future<void> markPaymentPaid(String paymentId) async {
    try {
      await _client.from('payments').update({
        'status': 'paid',
        'paid_date': DateTime.now().toIso8601String().substring(0, 10),
        'paid_by': _uid,
      }).eq('id', paymentId);
    } catch (e) {
      throw Exception('Failed to mark payment as paid: $e');
    }
  }

  // ─── DOCUMENTS ──────────────────────────────────────────

  static Future<List<AppDocument>> getDocuments(String projectId, {String? docType}) async {
    try {
      var query = _client.from('documents').select().eq('project_id', projectId);
      if (docType != null) query = query.eq('doc_type', docType);
      final res = await query.order('created_at', ascending: false);
      return res.map((e) => AppDocument.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load documents: $e');
    }
  }

  static Future<AppDocument> uploadDocument({
    required String projectId,
    required File file,
    required String title,
    required String docType,
    String? phaseId,
    String? taskId,
    String? planningItemId,
    String? issueId,
    String? dailyLogId,
    String? notes,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final path = '$projectId/$fileName';
      await _client.storage.from(AppConfig.documentsBucket).upload(path, file);
      final fileUrl = _client.storage.from(AppConfig.documentsBucket).getPublicUrl(path);
      final stat = await file.stat();
      final res = await _client.from('documents').insert({
        'project_id': projectId,
        'phase_id': phaseId,
        'task_id': taskId,
        'planning_item_id': planningItemId,
        'issue_id': issueId,
        'daily_log_id': dailyLogId,
        'title': title,
        'doc_type': docType,
        'file_url': fileUrl,
        'file_name': fileName,
        'file_size_bytes': stat.size,
        'mime_type': _getMimeType(fileName),
        'uploaded_by': _uid,
        'notes': notes,
      }).select().single();
      return AppDocument.fromJson(res);
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  static String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg': case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'pdf': return 'application/pdf';
      default: return 'application/octet-stream';
    }
  }

  // ─── NOTIFICATIONS ──────────────────────────────────────

  static Future<List<AppNotification>> getNotifications() async {
    try {
      final res = await _client.from('notifications').select()
          .eq('user_id', _uid).order('created_at', ascending: false).limit(50);
      return res.map((e) => AppNotification.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load notifications: $e');
    }
  }

  static Future<int> getUnreadCount() async {
    try {
      final res = await _client.from('notifications').select('id')
          .eq('user_id', _uid).eq('is_read', false);
      return res.length;
    } catch (e) {
      return 0; // Non-critical — silently return 0
    }
  }

  static Future<void> markAllNotificationsRead() async {
    try {
      await _client.from('notifications').update({'is_read': true})
          .eq('user_id', _uid).eq('is_read', false);
    } catch (e) {
      throw Exception('Failed to mark notifications as read: $e');
    }
  }

  // ─── REALTIME ───────────────────────────────────────────

  // FIX: Returns typed RealtimeChannel (was returning dynamic before)
  static RealtimeChannel subscribeToNotifications(void Function(AppNotification) onNew) {
    return _client.channel('notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _uid,
          ),
          callback: (payload) => onNew(AppNotification.fromJson(payload.newRecord)),
        )
        .subscribe();
  }
}
