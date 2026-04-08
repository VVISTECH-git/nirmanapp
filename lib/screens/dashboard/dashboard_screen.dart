// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/shared_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = ref.watch(selectedProjectIdProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    if (projectId == null) {
      return _NoProjectScreen(ref: ref);
    }

    final projectAsync = ref.watch(selectedProjectProvider);
    final phasesAsync = ref.watch(phasesProvider(projectId));
    final todayLogAsync = ref.watch(todayLogProvider(projectId));
    final unreadAsync = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: projectAsync.when(
        loading: () => const LoadingScreen(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (project) {
          if (project == null) return const LoadingScreen();
          final profile = profileAsync.valueOrNull;
          final unread = unreadAsync.valueOrNull ?? 0;

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: const Color(0xFF378ADD),
                expandedHeight: 120,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: const Color(0xFF378ADD),
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Good ${_greeting()}, ${profile?.displayName.split(' ').first ?? ''}!',
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  GestureDetector(
                                    onTap: () => context.push('/projects'),
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            project.name,
                                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 18),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Stack(
                              children: [
                                IconButton(
                                  onPressed: () => context.push('/notifications'),
                                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                                ),
                                if (unread > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: const BoxDecoration(color: Color(0xFFE24B4A), shape: BoxShape.circle),
                                      child: Center(
                                        child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (profile?.isSuperAdmin == true)
                              IconButton(
                                onPressed: () => context.push('/admin'),
                                icon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Daily Log CTA
                      todayLogAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (todayLog) => _DailyLogCTA(
                          hasLog: todayLog != null,
                          onTap: () => context.push(todayLog != null ? '/daily-log' : '/daily-log/add'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Metrics
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.6,
                        children: [
                          MetricCard(
                            label: 'Total budget',
                            value: formatRupees(project.totalBudgetPaise, compact: true),
                          ),
                          MetricCard(
                            label: 'Spent so far',
                            value: formatRupees(project.totalSpentPaise ?? 0, compact: true),
                            valueColor: const Color(0xFFE24B4A),
                          ),
                          MetricCard(
                            label: 'Open tasks',
                            value: '${project.openTasks ?? 0}',
                            valueColor: project.overdueTasks != null && project.overdueTasks! > 0
                                ? const Color(0xFFE24B4A) : null,
                          ),
                          MetricCard(
                            label: 'Open issues',
                            value: '${project.openIssues ?? 0}',
                            valueColor: project.openIssues != null && project.openIssues! > 0
                                ? const Color(0xFFD85A30) : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Budget progress
                      _BudgetProgress(project: project),
                      const SizedBox(height: 20),

                      // Phase progress
                      SectionHeader('Phase progress', action: 'View plan', onAction: () => context.go('/plan')),
                      phasesAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('$e'),
                        data: (phases) => Column(
                          children: phases.map((p) => _PhaseProgressTile(phase: p)).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Quick actions
                      SectionHeader('Quick actions'),
                      _QuickActions(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}

class _NoProjectScreen extends StatelessWidget {
  final WidgetRef ref;
  const _NoProjectScreen({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EmptyState(
        title: 'No project yet',
        subtitle: 'Create your first construction project to get started',
        icon: Icons.construction_outlined,
        buttonLabel: 'Create project',
        onButton: () => context.push('/create-project'),
      ),
    );
  }
}

class _DailyLogCTA extends StatelessWidget {
  final bool hasLog;
  final VoidCallback onTap;
  const _DailyLogCTA({required this.hasLog, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasLog ? const Color(0xFFEAF3DE) : const Color(0xFFFAEEDA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasLog ? const Color(0xFF1D9E75) : const Color(0xFFEF9F27), width: 0.5),
        ),
        child: Row(
          children: [
            Icon(
              hasLog ? Icons.check_circle : Icons.edit_note,
              color: hasLog ? const Color(0xFF1D9E75) : const Color(0xFFBA7517),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasLog ? 'Today\'s log submitted' : 'Log today\'s site activity',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: hasLog ? const Color(0xFF1D9E75) : const Color(0xFFBA7517),
                    ),
                  ),
                  Text(
                    hasLog ? 'Tap to view or edit' : 'Workers, work done, materials used...',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: hasLog ? const Color(0xFF1D9E75) : const Color(0xFFBA7517)),
          ],
        ),
      ),
    );
  }
}

class _BudgetProgress extends StatelessWidget {
  final project;
  const _BudgetProgress({required this.project});

  @override
  Widget build(BuildContext context) {
    final pct = project.progressPercent;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Budget utilization', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text('${pct.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF378ADD))),
            ],
          ),
          const SizedBox(height: 10),
          NirmanProgressBar(
            progress: pct,
            color: pct > 90 ? const Color(0xFFE24B4A) : pct > 75 ? const Color(0xFFEF9F27) : const Color(0xFF1D9E75),
            height: 8,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Spent: ${formatRupees(project.totalSpentPaise ?? 0, compact: true)}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
              Text('Budget: ${formatRupees(project.totalBudgetPaise, compact: true)}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhaseProgressTile extends StatelessWidget {
  final phase;
  const _PhaseProgressTile({required this.phase});

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(phase.color.replaceAll('#', '0xFF')));
    final pct = phase.progressPct ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(phase.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              StatusBadge(phase.status, fontSize: 10),
            ],
          ),
          const SizedBox(height: 8),
          NirmanProgressBar(progress: pct, color: color),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${phase.doneTasks ?? 0}/${phase.totalTasks ?? 0} tasks',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
              Text('${pct.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      {'icon': Icons.add_task, 'label': 'Add task', 'route': '/tasks', 'color': 0xFF378ADD},
      {'icon': Icons.bug_report_outlined, 'label': 'Log issue', 'route': '/issues', 'color': 0xFFE24B4A},
      {'icon': Icons.payments_outlined, 'label': 'Add expense', 'route': '/expenses/add', 'color': 0xFF1D9E75},
      {'icon': Icons.people_outline, 'label': 'Resources', 'route': '/resources', 'color': 0xFF7F77DD},
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: actions.map((a) {
        return GestureDetector(
          onTap: () => context.go(a['route'] as String),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(a['icon'] as IconData, color: Color(a['color'] as int), size: 24),
                const SizedBox(height: 4),
                Text(a['label'] as String,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF666666)),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
