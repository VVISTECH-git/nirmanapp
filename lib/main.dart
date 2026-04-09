// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'config/app_config.dart';
import 'config/app_theme.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/plan/project_plan_screen.dart';
import 'screens/tasks/tasks_screen.dart';
import 'screens/expenses/expenses_screen.dart';
import 'screens/docs/docs_screen.dart';
import 'screens/daily_log/daily_log_form_screen.dart';
import 'screens/issues/issues_screen.dart';
import 'screens/plan/phase_detail_screen.dart';
import 'screens/resources/resources_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/dashboard/create_project_screen.dart';
import 'widgets/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: NirmanApp(),
    ),
  );
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
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

class NirmanApp extends ConsumerWidget {
  const NirmanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppConfig.appName,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
