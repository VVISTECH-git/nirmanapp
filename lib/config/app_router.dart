// lib/config/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../services/supabase_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/pending_approval_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/dashboard/create_project_screen.dart';
import '../screens/plan/project_plan_screen.dart';
import '../screens/plan/phase_detail_screen.dart';
import '../screens/tasks/tasks_screen.dart';
import '../screens/expenses/expenses_screen.dart';
import '../screens/docs/docs_screen.dart';
import '../screens/daily_log/daily_log_form_screen.dart';
import '../screens/issues/issues_screen.dart';
import '../screens/resources/resources_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/admin/admin_screen.dart';
import '../widgets/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final profile = ref.watch(currentProfileProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final user = SupabaseService.currentUser;
      final isLoginRoute = state.matchedLocation == '/login';
      final isPendingRoute = state.matchedLocation == '/pending';

      if (user == null) {
        return isLoginRoute ? null : '/login';
      }

      final profileData = profile.valueOrNull;
      if (profileData == null) return null;

      if (!profileData.isApproved && !profileData.isSuperAdmin) {
        return isPendingRoute ? null : '/pending';
      }

      if (isLoginRoute || isPendingRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/pending', builder: (_, __) => const PendingApprovalScreen()),
      GoRoute(path: '/create-project', builder: (_, __) => const CreateProjectScreen()),
      GoRoute(path: '/projects', builder: (_, __) => const ProjectSelectionScreen()),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/plan', builder: (_, __) => const ProjectPlanScreen()),
          GoRoute(
            path: '/plan/phase/:phaseId',
            builder: (_, state) => PhaseDetailScreen(phaseId: state.pathParameters['phaseId']!),
          ),
          GoRoute(path: '/tasks', builder: (_, __) => const TasksScreen()),
          GoRoute(
            path: '/tasks/:taskId',
            builder: (_, state) => TaskDetailScreen(taskId: state.pathParameters['taskId']!),
          ),
          GoRoute(path: '/expenses', builder: (_, __) => const ExpensesScreen()),
          GoRoute(path: '/expenses/add', builder: (_, __) => const AddExpenseScreen()),
          GoRoute(path: '/payments', builder: (_, __) => const PaymentsScreen()),
          GoRoute(path: '/docs', builder: (_, __) => const DocsScreen()),
          GoRoute(path: '/daily-log', builder: (_, __) => const DailyLogScreen()),
          GoRoute(path: '/daily-log/add', builder: (_, __) => const DailyLogFormScreen()),
          GoRoute(path: '/issues', builder: (_, __) => const IssuesScreen()),
          GoRoute(
            path: '/issues/:issueId',
            builder: (_, state) => IssueDetailScreen(issueId: state.pathParameters['issueId']!),
          ),
          GoRoute(path: '/resources', builder: (_, __) => const ResourcesScreen()),
          GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),
        ],
      ),
    ],
  );
});
