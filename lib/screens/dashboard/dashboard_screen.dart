// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/models.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch project init - this triggers auto-load
    final initAsync = ref.watch(projectInitProvider);
    final projectId = ref.watch(selectedProjectIdProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    // Show loading while init is running
    if (initAsync.isLoading) {
      return const LoadingScreen();
    }

    if (projectId == null) {
      return _NoProjectScreen(ref: ref);
    }

    final projectAsync = ref.watch(selectedProjectProvider);
    final phasesAsync = ref.watch(phasesProvider(projectId));
    final todayLogAsync = ref.watch(todayLogProvider(projectId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: projectAsync.when(
        loading: () => const LoadingScreen(),
        error: (e, _) => EmptyState(title: 'Error', subtitle: e.toString(), icon: Icons.error_outline),
        data: (project) {
          if (project == null) return const LoadingScreen();
          final profile = profileAsync.valueOrNull;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                backgroundColor: const Color(0xFF1A2B4A),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: const Color(0xFF1A2B4A),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                            if (profile?.isSuperAdmin == true)
                              IconButton(
                                icon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white70),
                                onPressed: () => context.push('/admin'),
                              ),
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined, color: Colors.white70),
                              onPressed: () => context.push('/notifications'),
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
                      // Daily log CTA
                      todayLogAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (log) => log == null
                            ? GestureDetector(
                                onTap: () => context.push('/daily-log/add'),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFF8EC),
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.edit_note, color: Color(0xFFEF9F27)),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text("Log today's site activity",
                                            style: TextStyle(color: Color(0xFFEF9F27), fontWeight: FontWeight.w500)),
                                      ),
                                      Icon(Icons.arrow_forward_ios, color: Color(0xFFEF9F27), size: 14),
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      // Metrics
                      Row(
                        children: [
                          Expanded(child: MetricCard(label: 'Budget', value: formatRupees(project.totalBudgetPaise, compact: true))),
                          const SizedBox(width: 10),
                          Expanded(child: MetricCard(label: 'Spent', value: formatRupees(project.totalSpentPaise ?? 0, compact: true))),
                          const SizedBox(width: 10),
                          Expanded(child: MetricCard(
                            label: 'Tasks',
                            value: '${project.openTasks ?? 0}',
                            valueColor: project.overdueTasks != null && project.overdueTasks! > 0
                                ? const Color(0xFFE24B4A) : null,
                          )),
                          const SizedBox(width: 10),
                          Expanded(child: MetricCard(
                            label: 'Issues',
                            value: '${project.openIssues ?? 0}',
                            valueColor: project.openIssues != null && project.openIssues! > 0
                                ? const Color(0xFFE24B4A) : null,
                          )),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Budget progress
                      _BudgetProgress(project: project),
                      const SizedBox(height: 16),

                      // Quick actions
                      const SectionHeader('Quick actions'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _QuickAction(icon: Icons.add_task, label: 'Add task', onTap: () => context.push('/tasks'))),
                          const SizedBox(width: 10),
                          Expanded(child: _QuickAction(icon: Icons.warning_amber_outlined, label: 'Log issue', onTap: () => context.push('/issues'))),
                          const SizedBox(width: 10),
                          Expanded(child: _QuickAction(icon: Icons.receipt_long_outlined, label: 'Add expense', onTap: () => context.push('/expenses'))),
                          const SizedBox(width: 10),
                          Expanded(child: _QuickAction(icon: Icons.people_outline, label: 'Resources', onTap: () => context.push('/resources'))),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Phase progress
                      const SectionHeader('Phase progress'),
                      const SizedBox(height: 10),
                      phasesAsync.when(
                        loading: () => const LoadingScreen(),
                        error: (e, _) => const SizedBox.shrink(),
                        data: (phases) => Column(
                          children: phases.map((phase) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PhaseProgressCard(phase: phase),
                          )).toList(),
                        ),
                      ),
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
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

class _NoProjectScreen extends StatelessWidget {
  final WidgetRef ref;
  const _NoProjectScreen({required this.ref});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.construction,
      title: 'No project yet',
      subtitle: 'Create your first construction project to get started',
      buttonLabel: 'Create project',
      onButton: () => context.push('/create-project'),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE8ECF0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF378ADD), size: 22),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF666666)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _PhaseProgressCard extends StatelessWidget {
  final Phase phase;
  const _PhaseProgressCard({required this.phase});

  @override
  Widget build(BuildContext context) {
    final pct = phase.progressPct ?? 0.0;
    final color = Color(int.parse(phase.color.replaceFirst('#', '0xFF')));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(phase.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ),
              StatusBadge(phase.status),
            ],
          ),
          const SizedBox(height: 8),
          NirmanProgressBar(progress: pct, color: color),
          const SizedBox(height: 4),
          Text('${(pct * 100).round()}% complete',
              style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
        ],
      ),
    );
  }
}

class _BudgetProgress extends StatelessWidget {
  final Project project;
  const _BudgetProgress({required this.project});

  @override
  Widget build(BuildContext context) {
    final pct = project.progressPercent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Budget utilization', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              Text('${(pct * 100).round()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF378ADD))),
            ],
          ),
          const SizedBox(height: 10),
          NirmanProgressBar(progress: pct, color: const Color(0xFF378ADD)),
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
