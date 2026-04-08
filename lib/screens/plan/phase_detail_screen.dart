// lib/screens/plan/phase_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/supabase_service.dart';

class PhaseDetailScreen extends ConsumerWidget {
  final String phaseId;
  const PhaseDetailScreen({super.key, required this.phaseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = ref.watch(selectedProjectIdProvider);
    if (projectId == null) return const LoadingScreen();

    final phasesAsync = ref.watch(phasesProvider(projectId));
    final phase = phasesAsync.valueOrNull?.firstWhere((p) => p.id == phaseId, orElse: () => throw Exception('Not found'));
    final tasksAsync = ref.watch(tasksProvider(projectId));

    if (phase == null) return const LoadingScreen();

    final color = Color(int.parse(phase.color.replaceAll('#', '0xFF')));
    final tasks = tasksAsync.valueOrNull?.where((t) => t.phaseId == phaseId).toList() ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: Text(phase.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phase summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: color, width: 4)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatusBadge(phase.status),
                      Text('${(phase.progressPct ?? 0).toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  NirmanProgressBar(progress: phase.progressPct ?? 0, color: color, height: 8),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                      ),
                    ],
                  ),
                  Row(children: [
                    Expanded(child: _statItem('Total tasks', '${phase.totalTasks ?? 0}')),
                    Expanded(child: _statItem('Done', '${phase.doneTasks ?? 0}', const Color(0xFF1D9E75))),
                    Expanded(child: _statItem('Budget', formatRupees(phase.budgetPaise, compact: true))),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionHeader('Tasks (${tasks.length})'),
            if (tasks.isEmpty)
              const EmptyState(title: 'No tasks', subtitle: 'Add tasks for this phase', icon: Icons.task_outlined)
            else
              ...tasks.map((t) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5)),
                child: Row(
                  children: [
                    Expanded(child: Text(t.title, style: const TextStyle(fontSize: 13))),
                    StatusBadge(t.status, fontSize: 10),
                  ],
                ),
              )),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, [Color? color]) => Column(
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color ?? const Color(0xFF1A1A1A))),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────

// lib/screens/tasks/task_detail_screen.dart
class TaskDetailScreen extends ConsumerWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = ref.watch(selectedProjectIdProvider);
    if (projectId == null) return const LoadingScreen();

    final tasksAsync = ref.watch(tasksProvider(projectId));
    final task = tasksAsync.valueOrNull?.firstWhere((t) => t.id == taskId, orElse: () => throw Exception('Not found'));

    if (task == null) return const LoadingScreen();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Task detail'),
        actions: [
          if (task.status != 'done')
            TextButton(
              onPressed: () async {
                await SupabaseService.updateTask(task.id, {
                  'status': 'done',
                  'completed_date': DateTime.now().toIso8601String(),
                });
                ref.invalidate(tasksProvider(projectId));
              },
              child: const Text('Mark done'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Row(children: [
                    StatusBadge(task.status),
                    const SizedBox(width: 8),
                    PriorityBadge(task.priority),
                  ]),
                  if (task.description != null) ...[
                    const SizedBox(height: 12),
                    Text(task.description!, style: const TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.5)),
                  ],
                  const Divider(height: 24),
                  if (task.phaseName != null) _detailRow(Icons.layers_outlined, 'Phase', task.phaseName!),
                  if (task.assignedToName != null) _detailRow(Icons.person_outline, 'Assigned to', task.assignedToName!),
                  if (task.dueDate != null) _detailRow(Icons.calendar_today, 'Due date', '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}'),
                  if (task.completedDate != null) _detailRow(Icons.check_circle_outline, 'Completed', '${task.completedDate!.day}/${task.completedDate!.month}/${task.completedDate!.year}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9E9E9E)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

// lib/screens/issues/issue_detail_screen.dart
class IssueDetailScreen extends ConsumerWidget {
  final String issueId;
  const IssueDetailScreen({super.key, required this.issueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = ref.watch(selectedProjectIdProvider);
    if (projectId == null) return const LoadingScreen();

    final issuesAsync = ref.watch(issuesProvider(projectId));
    final issue = issuesAsync.valueOrNull?.firstWhere((i) => i.id == issueId, orElse: () => throw Exception('Not found'));

    if (issue == null) return const LoadingScreen();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Issue detail'),
        actions: [
          if (issue.status == 'open' || issue.status == 'in_progress')
            TextButton(
              onPressed: () async {
                await SupabaseService.updateIssue(issue.id, {
                  'status': 'resolved',
                  'resolved_at': DateTime.now().toIso8601String(),
                });
                ref.invalidate(issuesProvider(projectId));
              },
              child: const Text('Resolve'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(issue.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Row(children: [StatusBadge(issue.status), const SizedBox(width: 8), PriorityBadge(issue.priority)]),
              if (issue.description != null) ...[
                const SizedBox(height: 12),
                Text(issue.description!, style: const TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.5)),
              ],
              const Divider(height: 24),
              _detailRow('Reported by', issue.reportedByName ?? 'Unknown'),
              _detailRow('Date', '${issue.createdAt.day}/${issue.createdAt.month}/${issue.createdAt.year}'),
              if (issue.phaseName != null) _detailRow('Phase', issue.phaseName!),
              if (issue.resolvedAt != null) _detailRow('Resolved', '${issue.resolvedAt!.day}/${issue.resolvedAt!.month}/${issue.resolvedAt!.year}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

// lib/screens/daily_log/daily_log_screen.dart
class DailyLogScreen extends ConsumerWidget {
  const DailyLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = ref.watch(selectedProjectIdProvider);
    if (projectId == null) return const LoadingScreen();

    final logsAsync = ref.watch(dailyLogsProvider(projectId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Daily site log')),
      body: logsAsync.when(
        loading: () => const LoadingScreen(),
        error: (e, _) => Center(child: Text('$e')),
        data: (logs) {
          if (logs.isEmpty) {
            return EmptyState(
              title: 'No logs yet',
              subtitle: 'Start logging daily site activity',
              icon: Icons.edit_note,
              buttonLabel: 'Log today',
              onButton: () => Navigator.pushNamed(context, '/daily-log/add'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (_, i) {
              final log = logs[i];
              final isToday = log.logDate.year == DateTime.now().year &&
                  log.logDate.month == DateTime.now().month &&
                  log.logDate.day == DateTime.now().day;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isToday ? const Color(0xFF378ADD) : const Color(0xFFEEEEEE), width: isToday ? 1.5 : 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isToday ? 'Today' : '${log.logDate.day}/${log.logDate.month}/${log.logDate.year}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isToday ? const Color(0xFF378ADD) : const Color(0xFF1A1A1A)),
                        ),
                        const Spacer(),
                        if (log.weather != null) ...[
                          const Icon(Icons.wb_sunny_outlined, size: 14, color: Color(0xFF9E9E9E)),
                          const SizedBox(width: 4),
                          Text(log.weather!, style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                        ],
                        const SizedBox(width: 8),
                        const Icon(Icons.people_outline, size: 14, color: Color(0xFF9E9E9E)),
                        const SizedBox(width: 4),
                        Text('${log.workersPresent}', style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                      ],
                    ),
                    if (log.workSummary != null) ...[
                      const SizedBox(height: 8),
                      Text(log.workSummary!, style: const TextStyle(fontSize: 13, color: Color(0xFF444444), height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    if (log.issuesNoted != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_outlined, size: 13, color: Color(0xFFBA7517)),
                          const SizedBox(width: 4),
                          Expanded(child: Text(log.issuesNoted!, style: const TextStyle(fontSize: 12, color: Color(0xFFBA7517)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: NirmanFAB(onTap: () => context.push('/daily-log/add'), label: 'Log today'),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

// lib/screens/expenses/add_expense_screen.dart
class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});
  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'misc';
  DateTime _date = DateTime.now();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final projectId = ref.watch(selectedProjectIdProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Add expense'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title *', hintText: 'e.g. Cement purchase')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: _amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹) *', prefixText: '₹ '))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _gstCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'GST (₹)', prefixText: '₹ '))),
            ]),
            const SizedBox(height: 12),
            NirmanDropdown<String>(
              label: 'Category',
              selected: _category,
              items: const {
                'materials': 'Materials',
                'labour': 'Labour',
                'equipment': 'Equipment',
                'professional_fees': 'Professional fees',
                'approvals': 'Approvals',
                'misc': 'Miscellaneous',
              },
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 12),
            TextField(controller: _descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes', hintText: 'Optional notes')),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
                if (d != null) setState(() => _date = d);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE0E0E0))),
                child: Row(children: [
                  const Icon(Icons.calendar_today, size: 16, color: Color(0xFF9E9E9E)),
                  const SizedBox(width: 8),
                  Text('${_date.day}/${_date.month}/${_date.year}', style: const TextStyle(fontSize: 14)),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : () => _submit(projectId!),
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save expense', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit(String projectId) async {
    if (_titleCtrl.text.trim().isEmpty || _amountCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await SupabaseService.createExpense({
        'project_id': projectId,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'category': _category,
        'amount_paise': (double.parse(_amountCtrl.text) * 100).round(),
        'gst_paise': _gstCtrl.text.isEmpty ? 0 : (double.parse(_gstCtrl.text) * 100).round(),
        'expense_date': _date.toIso8601String().substring(0, 10),
      });
      ref.invalidate(expensesProvider(projectId));
      ref.invalidate(expenseSummaryProvider(projectId));
      ref.invalidate(selectedProjectProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

// lib/screens/payments/payments_screen.dart
class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Center(child: Text('Payments — accessed via Money tab')),
    );
  }
}

