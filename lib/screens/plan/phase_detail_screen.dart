import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PhaseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> phase;
  final String projectId;
  const PhaseDetailScreen({super.key, required this.phase, required this.projectId});

  @override
  State<PhaseDetailScreen> createState() => _PhaseDetailScreenState();
}

class _PhaseDetailScreenState extends State<PhaseDetailScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _tasks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final res = await _client
          .from('tasks')
          .select()
          .eq('project_id', widget.projectId)
          .eq('phase_id', widget.phase['id'])
          .order('due_date', ascending: true);
      if (mounted) {
        setState(() { _tasks = List<Map<String, dynamic>>.from(res); _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _updateTaskStatus(String taskId, String newStatus) async {
    await _client.from('tasks').update({'status': newStatus}).eq('id', taskId);
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    final phase = widget.phase;
    final pct = ((phase['progress_pct'] ?? 0.0) as num).toDouble();

    return Scaffold(
      appBar: AppBar(title: Text(phase['name'] ?? '')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : Column(children: [
                  // Phase progress header
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('${_tasks.where((t) => t['status'] == 'done').length} of ${_tasks.length} tasks done',
                            style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        Text('${pct.round()}%',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: pct / 100,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ]),
                  ),
                  const Divider(height: 1),

                  // Tasks list
                  Expanded(
                    child: _tasks.isEmpty
                        ? const Center(child: Text('No tasks for this phase',
                            style: TextStyle(color: Colors.grey)))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _tasks.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) => _TaskCard(
                              task: _tasks[i],
                              onStatusChange: (status) =>
                                  _updateTaskStatus(_tasks[i]['id'], status),
                            ),
                          ),
                  ),
                ]),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final Function(String) onStatusChange;
  const _TaskCard({required this.task, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    final status = task['status'] ?? 'todo';
    final priority = task['priority'] ?? 'medium';
    final isDone = status == 'done';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        // Checkbox
        GestureDetector(
          onTap: () => onStatusChange(isDone ? 'todo' : 'done'),
          child: Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? Colors.green : Colors.transparent,
              border: Border.all(
                color: isDone ? Colors.green : Colors.grey.shade400,
                width: 2,
              ),
            ),
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        // Task info
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(task['title'] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                decoration: isDone ? TextDecoration.lineThrough : null,
                color: isDone ? Colors.grey : Colors.black,
              )),
          if (task['due_date'] != null) ...[
            const SizedBox(height: 3),
            Text('Due: ${task['due_date'].toString().substring(0, 10)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ])),
        // Priority badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _priorityColor(priority).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(priority,
              style: TextStyle(fontSize: 11, color: _priorityColor(priority))),
        ),
      ]),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'critical': return Colors.red;
      case 'high': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.blue;
    }
  }
}
