// lib/services/supabase_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';
import '../config/app_config.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;

  // ─── AUTH ───────────────────────────────────────────────

  static Future<bool> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS ? AppConfig.googleClientIdIOS : null,
        serverClientId: AppConfig.googleClientIdWeb,
        scopes: ['email', 'profile'],
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return false;

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) return false;

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _client.auth.signOut();
  }

  static User? get currentUser => _client.auth.currentUser;

  static Stream<AuthState> get authStateStream => _client.auth.onAuthStateChange;

  // ─── PROFILES ───────────────────────────────────────────

  static Future<UserProfile?> getProfile(String userId) async {
    final res = await _client.from('profiles').select().eq('id', userId).maybeSingle();
    return res != null ? UserProfile.fromJson(res) : null;
  }

  static Future<List<UserProfile>> getPendingUsers() async {
    final res = await _client
        .from('profiles')
        .select()
        .eq('access_status', 'pending')
        .order('requested_at', ascending: true);
    return res.map((e) => UserProfile.fromJson(e)).toList();
  }

  static Future<List<UserProfile>> getApprovedUsers() async {
    final res = await _client
        .from('profiles')
        .select()
        .eq('access_status', 'approved')
        .order('full_name', ascending: true);
    return res.map((e) => UserProfile.fromJson(e)).toList();
  }

  static Future<void> approveUser(String userId) async {
    await _client.from('profiles').update({
      'access_status': 'approved',
      'approved_at': DateTime.now().toIso8601String(),
      'approved_by': currentUser!.id,
    }).eq('id', userId);
    await _client.from('notifications').insert({
      'user_id': userId,
      'title': 'Access approved!',
      'body': 'You can now access NirmanApp. Welcome aboard!',
      'type': 'access_approved',
    });
  }

  static Future<void> rejectUser(String userId) async {
    await _client.from('profiles').update({
      'access_status': 'rejected',
    }).eq('id', userId);
  }

  static Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _client.from('profiles').update(data).eq('id', userId);
  }

  // ─── PROJECTS ───────────────────────────────────────────

  static Future<List<Project>> getProjects() async {
    final res = await _client.from('project_summary').select().order('created_at', ascending: false);
    return res.map((e) => Project.fromJson(e)).toList();
  }

  static Future<Project?> getProject(String projectId) async {
    final res = await _client.from('project_summary').select().eq('id', projectId).maybeSingle();
    return res != null ? Project.fromJson(res) : null;
  }

  static Future<Project> createProject(Map<String, dynamic> data) async {
    final res = await _client.from('projects').insert({
      ...data,
      'owner_id': currentUser!.id,
    }).select().single();
    await _client.from('project_members').insert({
      'project_id': res['id'],
      'user_id': currentUser!.id,
      'role': 'admin',
    });
    await _createDefaultPhases(res['id']);
    return Project.fromJson(res);
  }

  static Future<void> _createDefaultPhases(String projectId) async {
    final templates = await _client.from('phase_templates').select().order('order_index');
    for (final t in templates) {
      final phaseRes = await _client.from('phases').insert({
        'project_id': projectId,
        'name': t['name'],
        'order_index': t['order_index'],
        'color': t['color'],
        'status': 'upcoming',
      }).select().single();

      if (t['name'] == 'Planning & approvals') {
        final itemTemplates = await _client
            .from('planning_item_templates')
            .select()
            .order('order_index');
        for (final it in itemTemplates) {
          await _client.from('planning_items').insert({
            'project_id': projectId,
            'phase_id': phaseRes['id'],
            'name': it['name'],
            'item_type': it['item_type'],
            'order_index': it['order_index'],
            'status': 'todo',
          });
        }
      }
    }
  }

  static Future<void> updateProject(String projectId, Map<String, dynamic> data) async {
    await _client.from('projects').update(data).eq('id', projectId);
  }

  // ─── PROJECT MEMBERS ────────────────────────────────────

  static Future<List<ProjectMember>> getProjectMembers(String projectId) async {
    final res = await _client
        .from('project_members')
        .select('*, profiles(*)')
        .eq('project_id', projectId);
    return res.map((e) => ProjectMember.fromJson(e)).toList();
  }

  static Future<void> addProjectMember(String projectId, String userId, String role) async {
    await _client.from('project_members').upsert({
      'project_id': projectId,
      'user_id': userId,
      'role': role,
      'invited_by': currentUser!.id,
    });
  }

  // ─── PHASES ─────────────────────────────────────────────

  static Future<List<Phase>> getPhases(String projectId) async {
    final res = await _client
        .from('phase_progress')
        .select()
        .eq('project_id', projectId)
        .order('order_index');
    return res.map((e) => Phase.fromJson(e)).toList();
  }

  static Future<Phase> createPhase(Map<String, dynamic> data) async {
    final res = await _client.from('phases').insert(data).select().single();
    return Phase.fromJson(res);
  }

  static Future<void> updatePhase(String phaseId, Map<String, dynamic> data) async {
    await _client.from('phases').update(data).eq('id', phaseId);
  }

  // ─── PLANNING ITEMS ─────────────────────────────────────

  static Future<List<PlanningItem>> getPlanningItems(String projectId) async {
    final res = await _client
        .from('planning_items')
        .select()
        .eq('project_id', projectId)
        .order('order_index');
    return res.map((e) => PlanningItem.fromJson(e)).toList();
  }

  static Future<void> updatePlanningItem(String id, Map<String, dynamic> data) async {
    await _client.from('planning_items').update(data).eq('id', id);
  }

  // ─── TASKS ──────────────────────────────────────────────

  static Future<List<Task>> getTasks(String projectId, {String? status, String? phaseId}) async {
    var query = _client.from('tasks').select().eq('project_id', projectId);
    if (status != null) query = query.eq('status', status);
    if (phaseId != null) query = query.eq('phase_id', phaseId);
    final res = await query.order('due_date', ascending: true);
    return res.map((e) => Task.fromJson(e)).toList();
  }

  static Future<Task> createTask(Map<String, dynamic> data) async {
    final res = await _client.from('tasks').insert({
      ...data,
      'created_by': currentUser!.id,
    }).select().single();
    return Task.fromJson(res);
  }

  static Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    await _client.from('tasks').update(data).eq('id', taskId);
  }

  static Future<void> deleteTask(String taskId) async {
    await _client.from('tasks').delete().eq('id', taskId);
  }

  // ─── ISSUES ─────────────────────────────────────────────

  static Future<List<Issue>> getIssues(String projectId, {String? status}) async {
    var query = _client.from('issues').select().eq('project_id', projectId);
    if (status != null) query = query.eq('status', status);
    final res = await query.order('created_at', ascending: false);
    return res.map((e) => Issue.fromJson(e)).toList();
  }

  static Future<Issue> createIssue(Map<String, dynamic> data) async {
    final res = await _client.from('issues').insert({
      ...data,
      'reported_by': currentUser!.id,
    }).select().single();
    return Issue.fromJson(res);
  }

  static Future<void> updateIssue(String issueId, Map<String, dynamic> data) async {
    await _client.from('issues').update(data).eq('id', issueId);
  }

  // ─── DAILY LOGS ─────────────────────────────────────────

  static Future<List<DailyLog>> getDailyLogs(String projectId, {int limit = 30}) async {
    final res = await _client
        .from('daily_logs')
        .select()
        .eq('project_id', projectId)
        .order('log_date', ascending: false)
        .limit(limit);
    return res.map((e) => DailyLog.fromJson(e)).toList();
  }

  static Future<DailyLog?> getTodayLog(String projectId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final res = await _client
        .from('daily_logs')
        .select()
        .eq('project_id', projectId)
        .eq('log_date', today)
        .maybeSingle();
    return res != null ? DailyLog.fromJson(res) : null;
  }

  static Future<DailyLog> upsertDailyLog(Map<String, dynamic> data) async {
    final res = await _client.from('daily_logs').upsert({
      ...data,
      'logged_by': currentUser!.id,
    }, onConflict: 'project_id,log_date').select().single();
    return DailyLog.fromJson(res);
  }

  // ─── CONTRACTORS ────────────────────────────────────────

  static Future<List<Contractor>> getContractors(String projectId) async {
    final res = await _client
        .from('contractors')
        .select()
        .eq('project_id', projectId)
        .order('name');
    return res.map((e) => Contractor.fromJson(e)).toList();
  }

  static Future<Contractor> createContractor(Map<String, dynamic> data) async {
    final res = await _client.from('contractors').insert(data).select().single();
    return Contractor.fromJson(res);
  }

  static Future<void> updateContractor(String id, Map<String, dynamic> data) async {
    await _client.from('contractors').update(data).eq('id', id);
  }

  // ─── MATERIALS ──────────────────────────────────────────

  static Future<List<Material>> getMaterials(String projectId) async {
    final res = await _client
        .from('materials')
        .select()
        .eq('project_id', projectId)
        .order('delivery_date', ascending: false);
    return res.map((e) => Material.fromJson(e)).toList();
  }

  static Future<Material> createMaterial(Map<String, dynamic> data) async {
    final res = await _client.from('materials').insert(data).select().single();
    return Material.fromJson(res);
  }

  // ─── EXPENSES ───────────────────────────────────────────

  static Future<List<Expense>> getExpenses(String projectId, {String? category}) async {
    var query = _client.from('expenses').select().eq('project_id', projectId);
    if (category != null) query = query.eq('category', category);
    final res = await query.order('expense_date', ascending: false);
    return res.map((e) => Expense.fromJson(e)).toList();
  }

  static Future<Expense> createExpense(Map<String, dynamic> data) async {
    final res = await _client.from('expenses').insert({
      ...data,
      'paid_by': currentUser!.id,
    }).select().single();
    return Expense.fromJson(res);
  }

  static Future<Map<String, int>> getExpenseSummary(String projectId) async {
    final res = await _client
        .from('expenses')
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

  // ─── PAYMENTS ───────────────────────────────────────────

  static Future<List<Payment>> getPayments(String projectId) async {
    final res = await _client
        .from('payments')
        .select()
        .eq('project_id', projectId)
        .order('due_date', ascending: true);
    return res.map((e) => Payment.fromJson(e)).toList();
  }

  static Future<Payment> createPayment(Map<String, dynamic> data) async {
    final res = await _client.from('payments').insert(data).select().single();
    return Payment.fromJson(res);
  }

  static Future<void> markPaymentPaid(String paymentId) async {
    await _client.from('payments').update({
      'status': 'paid',
      'paid_date': DateTime.now().toIso8601String().substring(0, 10),
      'paid_by': currentUser!.id,
    }).eq('id', paymentId);
  }

  // ─── DOCUMENTS ──────────────────────────────────────────

  static Future<List<AppDocument>> getDocuments(String projectId, {String? docType}) async {
    var query = _client.from('documents').select().eq('project_id', projectId);
    if (docType != null) query = query.eq('doc_type', docType);
    final res = await query.order('created_at', ascending: false);
    return res.map((e) => AppDocument.fromJson(e)).toList();
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
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final path = '$projectId/$fileName';

    await _client.storage.from(AppConfig.documentsBucket).upload(path, file);
    final fileUrl = _client.storage.from(AppConfig.documentsBucket).getPublicUrl(path);
    final stat = await file.stat();
    final mimeType = _getMimeType(fileName);

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
      'mime_type': mimeType,
      'uploaded_by': currentUser!.id,
      'notes': notes,
    }).select().single();

    return AppDocument.fromJson(res);
  }

  static String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg': case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'pdf': return 'application/pdf';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default: return 'application/octet-stream';
    }
  }

  // ─── NOTIFICATIONS ──────────────────────────────────────

  static Future<List<AppNotification>> getNotifications() async {
    final res = await _client
        .from('notifications')
        .select()
        .eq('user_id', currentUser!.id)
        .order('created_at', ascending: false)
        .limit(50);
    return res.map((e) => AppNotification.fromJson(e)).toList();
  }

  static Future<int> getUnreadCount() async {
    final res = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', currentUser!.id)
        .eq('is_read', false);
    return res.length;
  }

  static Future<void> markAllNotificationsRead() async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', currentUser!.id)
        .eq('is_read', false);
  }

  // ─── REALTIME ───────────────────────────────────────────

  static RealtimeChannel subscribeToNotifications(Function(AppNotification) onNew) {
    return _client
        .channel('notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUser!.id,
          ),
          callback: (payload) {
            onNew(AppNotification.fromJson(payload.newRecord));
          },
        )
        .subscribe();
  }
}
