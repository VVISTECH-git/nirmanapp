import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../plan/phase_detail_screen.dart';
import '../work/work_screen.dart';
import '../money/money_screen.dart';
import '../dailylog/daily_log_screen.dart';
import '../docs/docs_screen.dart';
import '../resources/resources_screen.dart';
import '../work/add_task_screen.dart';
import '../money/add_expense_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> project;
  const DashboardScreen({super.key, required this.project});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _phases = [];
  bool _loading = true;
  String? _error;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPhases();
  }

  Future<void> _loadPhases() async {
    try {
      final res = await _client
          .from('phase_progress')
          .select()
          .eq('project_id', widget.project['id'])
          .order('order_index');
      if (mounted) {
        setState(() { _phases = List<Map<String, dynamic>>.from(res); _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _HomeTab(project: widget.project, phases: _phases, loading: _loading, error: _error),
      _PlanTab(project: widget.project, phases: _phases, loading: _loading),
      WorkScreen(projectId: widget.project['id']),
      MoneyScreen(project: widget.project),
      DocsScreen(projectId: widget.project['id']),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(widget.project['name'] ?? '')),
      body: tabs[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Plan'),
          NavigationDestination(icon: Icon(Icons.task_outlined), selectedIcon: Icon(Icons.task), label: 'Work'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Money'),
          NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: 'Docs'),
        ],
      ),
    );
  }
}

// ─── HOME TAB ───────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final Map<String, dynamic> project;
  final List<Map<String, dynamic>> phases;
  final bool loading;
  final String? error;

  const _HomeTab({required this.project, required this.phases, required this.loading, this.error});

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text('Error: $error', style: const TextStyle(color: Colors.red)));

    final budgetPaise = (project['total_budget_paise'] ?? 0) as num;
    final spentPaise = (project['total_spent_paise'] ?? 0) as num;
    final budgetL = budgetPaise / 10000000;
    final spentL = spentPaise / 10000000;
    final pct = budgetPaise > 0 ? (spentPaise / budgetPaise).clamp(0.0, 1.0) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Daily Log CTA
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => AddDailyLogScreen(projectId: project['id']))),
          child: Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8EC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFCC80)),
            ),
            child: const Row(children: [
              Icon(Icons.edit_note, color: Colors.orange),
              SizedBox(width: 10),
              Expanded(child: Text("Log today's site activity",
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500))),
              Icon(Icons.arrow_forward_ios, color: Colors.orange, size: 14),
            ]),
          ),
        ),
        // Metrics
        Row(children: [
          _MetricCard(label: 'Budget', value: '₹${budgetL.toStringAsFixed(1)}L'),
          const SizedBox(width: 8),
          _MetricCard(label: 'Spent', value: '₹${spentL.toStringAsFixed(1)}L'),
          const SizedBox(width: 8),
          _MetricCard(label: 'Tasks', value: '${project['open_tasks'] ?? 0}'),
          const SizedBox(width: 8),
          _MetricCard(label: 'Issues', value: '${project['open_issues'] ?? 0}'),
        ]),
        const SizedBox(height: 16),

        // Budget progress
        const Text('Budget utilization', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: pct.toDouble(), minHeight: 8,
            borderRadius: BorderRadius.circular(4)),
        const SizedBox(height: 4),
        Text('${(pct * 100).round()}% of ₹${budgetL.toStringAsFixed(1)}L used',
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 16),

        // Quick actions
        Row(children: [
          Expanded(child: _QuickActionBtn(
            icon: Icons.people_outline, label: 'Resources',
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ResourcesScreen(projectId: project['id']))))),
          const SizedBox(width: 10),
          Expanded(child: _QuickActionBtn(
            icon: Icons.swap_horiz, label: 'Switch Project',
            onTap: () => Navigator.pop(context))),
        ]),
        const SizedBox(height: 24),

        // Phase summary
        const Text('Phase Progress', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 10),
        ...phases.map((phase) => _PhaseCard(phase: phase, onTap: null)),
      ]),
    );
  }
}

// ─── PLAN TAB ───────────────────────────────────────────
class _PlanTab extends StatelessWidget {
  final Map<String, dynamic> project;
  final List<Map<String, dynamic>> phases;
  final bool loading;

  const _PlanTab({required this.project, required this.phases, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: phases.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _PhaseCard(
        phase: phases[i],
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => PhaseDetailScreen(
            phase: phases[i],
            projectId: project['id'],
          ),
        )),
      ),
    );
  }
}

// ─── PLACEHOLDER TAB ────────────────────────────────────
class _PlaceholderTab extends StatelessWidget {
  final String label;
  const _PlaceholderTab({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('$label — coming soon',
        style: const TextStyle(fontSize: 16, color: Colors.grey)));
  }
}

// ─── SHARED WIDGETS ─────────────────────────────────────
class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickActionBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(children: [
          Icon(icon, color: const Color(0xFF378ADD), size: 22),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label, value;
  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  final Map<String, dynamic> phase;
  final VoidCallback? onTap;
  const _PhaseCard({required this.phase, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pct = ((phase['progress_pct'] ?? 0.0) as num).toDouble();
    final color = _statusColor(phase['status'] ?? 'upcoming');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(phase['name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w500))),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  (phase['status'] ?? '').toString().replaceAll('_', ' '),
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
              ]
            ]),
          ]),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: pct / 100,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
            color: color,
            backgroundColor: Colors.grey.shade100,
          ),
          const SizedBox(height: 4),
          Text('${pct.round()}% complete',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'done': return Colors.green;
      case 'in_progress': return Colors.blue;
      case 'on_hold': return Colors.orange;
      default: return Colors.grey;
    }
  }
}
