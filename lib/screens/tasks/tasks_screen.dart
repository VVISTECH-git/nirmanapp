// lib/screens/tasks/tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = ref.watch(selectedProjectIdProvider);
    if (projectId == null) return const LoadingScreen();

    final filter = ref.watch(taskFilterProvider);
    final tasksAsync = ref.watch(filteredTasksProvider(projectId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Work'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: FilterChips(
              options: const ['all', 'todo', 'in_progress', 'overdue', 'done'],
              labels: const ['All', 'To do', 'In progress', 'Overdue', 'Done'],
              selected: filter,
              onSelected: (v) => ref.read(taskFilterProvider.notifier).state = v,
            ),
          ),
        ),
      ),
      body: tasksAsync.when(
        loading: () => const LoadingScreen(),
        error: (e, _) => Center(child: Text('$e')),
        data: (tasks) {
          if (tasks.isEmpty) {
            return EmptyState(
              title: 'No tasks',
              subtitle: filter == 'all' ? 'Add your first task to get started' : 'No $filter tasks',
              icon: Icons.task_outlined,
              buttonLabel: filter == 'all' ? 'Add task' : null,
              onButton: () => _showAddTask(context, ref, projectId),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (_, i) => _TaskCard(task: tasks[i], ref: ref, projectId: projectId),
          );
        },
      ),
      floatingActionButton: NirmanFAB(
        onTap: () => _showAddTask(context, ref, projectId),
        label: 'Add task',
      ),
    );
  }

  void _showAddTask(BuildContext context, WidgetRef ref, String projectId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _AddTaskSheet(projectId: projectId, ref: ref),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final WidgetRef ref;
  final String projectId;

  const _TaskCard({required this.task, required this.ref, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: GestureDetector(
          onTap: () => _toggleDone(ref, projectId),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: task.status == 'done' ? const Color(0xFF1D9E75) : const Color(0xFFDDDDDD), width: 2),
              color: task.status == 'done' ? const Color(0xFF1D9E75) : Colors.transparent,
            ),
            child: task.status == 'done' ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            decoration: task.status == 'done' ? TextDecoration.lineThrough : null,
            color: task.status == 'done' ? const Color(0xFF9E9E9E) : const Color(0xFF1A1A1A),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Row(
              children: [
                if (task.phaseName != null) ...[
                  const Icon(Icons.layers_outlined, size: 11, color: Color(0xFF9E9E9E)),
                  const SizedBox(width: 3),
                  Text(task.phaseName!, style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                  const SizedBox(width: 8),
                ],
                if (task.assignedToName != null) ...[
                  const Icon(Icons.person_outline, size: 11, color: Color(0xFF9E9E9E)),
                  const SizedBox(width: 3),
                  Text(task.assignedToName!, style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                ],
              ],
            ),
            if (task.dueDate != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.schedule, size: 11,
                      color: task.isOverdue ? const Color(0xFFE24B4A) : const Color(0xFF9E9E9E)),
                  const SizedBox(width: 3),
                  Text(
                    _formatDate(task.dueDate!),
                    style: TextStyle(
                        fontSize: 11,
                        color: task.isOverdue ? const Color(0xFFE24B4A) : const Color(0xFF9E9E9E),
                        fontWeight: task.isOverdue ? FontWeight.w600 : FontWeight.normal),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: StatusBadge(task.status, fontSize: 10),
        onTap: () => context.push('/tasks/${task.id}'),
      ),
    );
  }

  void _toggleDone(WidgetRef ref, String projectId) async {
    final newStatus = task.status == 'done' ? 'todo' : 'done';
    await SupabaseService.updateTask(task.id, {
      'status': newStatus,
      'completed_date': newStatus == 'done' ? DateTime.now().toIso8601String() : null,
    });
    ref.invalidate(tasksProvider(projectId));
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff < 0) return '${diff.abs()} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _AddTaskSheet extends StatefulWidget {
  final String projectId;
  final WidgetRef ref;
  const _AddTaskSheet({required this.projectId, required this.ref});

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'medium';
  DateTime? _dueDate;
  bool _loading = false;

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
            const Text('New task', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: _titleCtrl, decoration: const InputDecoration(hintText: 'Task title', labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(controller: _descCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'Description (optional)', labelText: 'Description')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: NirmanDropdown<String>(
                    label: 'Priority',
                    selected: _priority,
                    items: const {'low': 'Low', 'medium': 'Medium', 'high': 'High', 'critical': 'Critical'},
                    onChanged: (v) => setState(() => _priority = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setState(() => _dueDate = d);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Text(
                        _dueDate != null ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}' : 'Due date',
                        style: TextStyle(color: _dueDate != null ? const Color(0xFF1A1A1A) : const Color(0xFFAAAAAA), fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Add task'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await SupabaseService.createTask({
        'project_id': widget.projectId,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'priority': _priority,
        'due_date': _dueDate?.toIso8601String().substring(0, 10),
        'status': 'todo',
      });
      widget.ref.invalidate(tasksProvider(widget.projectId));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

