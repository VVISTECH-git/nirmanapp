// lib/providers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

// ─── AUTH ────────────────────────────────────────────────

final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseService.authStateStream;
});

final currentUserProvider = Provider<User?>((ref) {
  return SupabaseService.currentUser;
});

final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return SupabaseService.getProfile(user.id);
});

// ─── SELECTED PROJECT ────────────────────────────────────

final selectedProjectIdProvider = StateProvider<String?>((ref) => null);

final selectedProjectProvider = FutureProvider<Project?>((ref) async {
  final id = ref.watch(selectedProjectIdProvider);
  if (id == null) return null;
  return SupabaseService.getProject(id);
});

// ─── PROJECTS ────────────────────────────────────────────

final projectsProvider = FutureProvider<List<Project>>((ref) async {
  return SupabaseService.getProjects();
});

// ─── PHASES ──────────────────────────────────────────────

final phasesProvider = FutureProvider.family<List<Phase>, String>((ref, projectId) async {
  return SupabaseService.getPhases(projectId);
});

final planningItemsProvider = FutureProvider.family<List<PlanningItem>, String>((ref, projectId) async {
  return SupabaseService.getPlanningItems(projectId);
});

// ─── TASKS ───────────────────────────────────────────────

final tasksProvider = FutureProvider.family<List<Task>, String>((ref, projectId) async {
  return SupabaseService.getTasks(projectId);
});

final taskFilterProvider = StateProvider<String>((ref) => 'all');

final filteredTasksProvider = Provider.family<AsyncValue<List<Task>>, String>((ref, projectId) {
  final tasksAsync = ref.watch(tasksProvider(projectId));
  final filter = ref.watch(taskFilterProvider);
  return tasksAsync.whenData((tasks) {
    if (filter == 'all') return tasks;
    if (filter == 'overdue') return tasks.where((t) => t.isOverdue).toList();
    return tasks.where((t) => t.status == filter).toList();
  });
});

// ─── ISSUES ──────────────────────────────────────────────

final issuesProvider = FutureProvider.family<List<Issue>, String>((ref, projectId) async {
  return SupabaseService.getIssues(projectId);
});

// ─── DAILY LOGS ──────────────────────────────────────────

final dailyLogsProvider = FutureProvider.family<List<DailyLog>, String>((ref, projectId) async {
  return SupabaseService.getDailyLogs(projectId);
});

final todayLogProvider = FutureProvider.family<DailyLog?, String>((ref, projectId) async {
  return SupabaseService.getTodayLog(projectId);
});

// ─── EXPENSES ────────────────────────────────────────────

final expensesProvider = FutureProvider.family<List<Expense>, String>((ref, projectId) async {
  return SupabaseService.getExpenses(projectId);
});

final expenseSummaryProvider = FutureProvider.family<Map<String, int>, String>((ref, projectId) async {
  return SupabaseService.getExpenseSummary(projectId);
});

// ─── PAYMENTS ────────────────────────────────────────────

final paymentsProvider = FutureProvider.family<List<Payment>, String>((ref, projectId) async {
  return SupabaseService.getPayments(projectId);
});

// ─── CONTRACTORS ─────────────────────────────────────────

final contractorsProvider = FutureProvider.family<List<Contractor>, String>((ref, projectId) async {
  return SupabaseService.getContractors(projectId);
});

// ─── MATERIALS ───────────────────────────────────────────

final materialsProvider = FutureProvider.family<List<Material>, String>((ref, projectId) async {
  return SupabaseService.getMaterials(projectId);
});

// ─── DOCUMENTS ───────────────────────────────────────────

final documentsProvider = FutureProvider.family<List<AppDocument>, String>((ref, projectId) async {
  return SupabaseService.getDocuments(projectId);
});

// ─── NOTIFICATIONS ───────────────────────────────────────

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  return SupabaseService.getNotifications();
});

final unreadCountProvider = FutureProvider<int>((ref) async {
  return SupabaseService.getUnreadCount();
});

// ─── ADMIN ───────────────────────────────────────────────

final pendingUsersProvider = FutureProvider<List<UserProfile>>((ref) async {
  return SupabaseService.getPendingUsers();
});

final approvedUsersProvider = FutureProvider<List<UserProfile>>((ref) async {
  return SupabaseService.getApprovedUsers();
});

final projectMembersProvider = FutureProvider.family<List<ProjectMember>, String>((ref, projectId) async {
  return SupabaseService.getProjectMembers(projectId);
});
