// lib/screens/plan/project_plan_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/supabase_service.dart';

class ProjectPlanScreen extends ConsumerWidget {
  const ProjectPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = ref.watch(selectedProjectIdProvider);
    if (projectId == null) return const LoadingScreen();

    final phasesAsync = ref.watch(phasesProvider(projectId));
    final planningItemsAsync = ref.watch(planningItemsProvider(projectId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Project plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddPhase(context, ref, projectId),
          ),
        ],
      ),
      body: phasesAsync.when(
        loading: () => const LoadingScreen(),
        error: (e, _) => Center(child: Text('$e')),
        data: (phases) {
          if (phases.isEmpty) {
            return EmptyState(
              title: 'No phases yet',
              subtitle: 'Add phases to your project plan',
              icon: Icons.view_timeline_outlined,
              buttonLabel: 'Add phase',
              onButton: () => _showAddPhase(context, ref, projectId),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: phases.length,
            itemBuilder: (context, i) {
              final phase = phases[i];
              final planningItems = phase.name.toLowerCase().contains('planning')
                  ? (planningItemsAsync.valueOrNull ?? [])
                  : null;
              return _PhaseCard(
                phase: phase,
                planningItems: planningItems,
                onTap: () => context.push('/plan/phase/${phase.id}'),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddPhase(BuildContext context, WidgetRef ref, String projectId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AddPhaseSheet(providerRef: ref, projectId: projectId),
    );
  }
}

class _AddPhaseSheet extends ConsumerStatefulWidget {
  final WidgetRef providerRef;
  final String projectId;
  const _AddPhaseSheet({required this.providerRef, required this.projectId});

  @override
  ConsumerState<_AddPhaseSheet> createState() => _AddPhaseSheetState();
}

class _AddPhaseSheetState extends ConsumerState<_AddPhaseSheet> {
  final _nameCtrl = TextEditingController();
  String _color = '#378ADD';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _loading = false;

  static const _colorOptions = {
    '#7F77DD': 'Purple',
    '#1D9E75': 'Green',
    '#378ADD': 'Blue',
    '#EF9F27': 'Amber',
    '#D85A30': 'Coral',
    '#D4537E': 'Pink',
    '#888780': 'Gray',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add phase', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Phase name *',
                hintText: 'e.g. Interior work',
              ),
            ),
            const SizedBox(height: 14),
            const Text('Color', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: _colorOptions.keys.map((hex) {
                final isSelected = _color == hex;
                return GestureDetector(
                  onTap: () => setState(() => _color = hex),
                  child: Container(
                    width: 30,
                    height: 30,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Color(int.parse(hex.replaceAll('#', '0xFF'))),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _datePicker('Start date', _startDate, (d) => setState(() => _startDate = d))),
                const SizedBox(width: 12),
                Expanded(child: _datePicker('End date', _endDate, (d) => setState(() => _endDate = d))),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add phase'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _datePicker(String label, DateTime? value, Function(DateTime) onPick) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (d != null) onPick(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 14, color: Color(0xFF9E9E9E)),
            const SizedBox(width: 6),
            Text(
              value != null ? '${value.day}/${value.month}/${value.year}' : label,
              style: TextStyle(
                fontSize: 12,
                color: value != null ? const Color(0xFF1A1A1A) : const Color(0xFFAAAAAA),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phase name')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await SupabaseService.createPhase({
        'project_id': widget.projectId,
        'name': _nameCtrl.text.trim(),
        'order_index': 99,
        'status': 'upcoming',
        'color': _color,
        'start_date': _startDate?.toIso8601String().substring(0, 10),
        'end_date': _endDate?.toIso8601String().substring(0, 10),
      });
      widget.providerRef.invalidate(phasesProvider(widget.projectId));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _PhaseCard extends StatefulWidget {
  final dynamic phase;
  final List? planningItems;
  final VoidCallback onTap;
  const _PhaseCard({required this.phase, this.planningItems, required this.onTap});

  @override
  State<_PhaseCard> createState() => _PhaseCardState();
}

class _PhaseCardState extends State<_PhaseCard> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.phase.status == 'in_progress';
  }

  @override
  Widget build(BuildContext context) {
    final phase = widget.phase;
    final color = Color(int.parse(phase.color.replaceAll('#', '0xFF')));
    final pct = (phase.progressPct ?? 0.0) as double;
    final hasSubItems = widget.planningItems != null && widget.planningItems!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: hasSubItems ? () => setState(() => _expanded = !_expanded) : widget.onTap,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(phase.name as String,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                      StatusBadge(phase.status as String),
                      if (hasSubItems) ...[
                        const SizedBox(width: 6),
                        Icon(
                          _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 18,
                          color: const Color(0xFF9E9E9E),
                        ),
                      ],
                    ],
                  ),
                  if (phase.startDate != null || phase.endDate != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 12, color: Color(0xFF9E9E9E)),
                        const SizedBox(width: 4),
                        Text(
                          _dateRange(phase.startDate, phase.endDate),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  NirmanProgressBar(progress: pct, color: color, height: 6),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${phase.doneTasks ?? 0}/${phase.totalTasks ?? 0} tasks',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                      Text('${pct.toStringAsFixed(0)}% complete',
                          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (hasSubItems && _expanded) ...[
            const Divider(height: 0, thickness: 0.5),
            ...widget.planningItems!.map((item) => _PlanningItemTile(item: item)),
          ],
          if (!hasSubItems)
            InkWell(
              onTap: widget.onTap,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('View details',
                        style: TextStyle(fontSize: 12, color: Color(0xFF378ADD), fontWeight: FontWeight.w500)),
                    Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF378ADD)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _dateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return 'Dates not set';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    String fmt(DateTime d) => '${d.day} ${months[d.month - 1]}';
    if (start != null && end != null) return '${fmt(start)} – ${fmt(end)}';
    if (start != null) return 'From ${fmt(start)}';
    return 'Until ${fmt(end!)}';
  }
}

class _PlanningItemTile extends StatelessWidget {
  final dynamic item;
  const _PlanningItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: _dotColor(item.status as String), shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name as String,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                if (item.assignedToName != null)
                  Text(item.assignedToName as String,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
              ],
            ),
          ),
          StatusBadge(item.status as String, fontSize: 10),
        ],
      ),
    );
  }

  Color _dotColor(String status) {
    switch (status) {
      case 'done': return const Color(0xFF1D9E75);
      case 'in_progress': return const Color(0xFFEF9F27);
      case 'overdue': return const Color(0xFFE24B4A);
      default: return const Color(0xFFCCCCCC);
    }
  }
}
