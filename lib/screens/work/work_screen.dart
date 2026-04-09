import 'add_task_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkScreen extends StatefulWidget {
  final String projectId;
  const WorkScreen({super.key, required this.projectId});

  @override
  State<WorkScreen> createState() => _WorkScreenState();
}

class _WorkScreenState extends State<WorkScreen> with SingleTickerProviderStateMixin {
  final _client = Supabase.instance.client;
  late TabController _tabController;

  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _issues = [];
  bool _loadingTasks = true;
  bool _loadingIssues = true;
  String _taskFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTasks();
    _loadIssues();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    try {
      final res = await _client
          .from('tasks')
          .select()
          .eq('project_id', widget.projectId)
          .order('due_date', ascending: true);
      if (mounted) setState(() { _tasks = List<Map<String, dynamic>>.from(res); _loadingTasks = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingTasks = false);
    }
  }

  Future<void> _loadIssues() async {
    try {
      final res = await _client
          .from('issues')
          .select()
          .eq('project_id', widget.projectId)
          .order('created_at', ascending: false);
      if (mounted) setState(() { _issues = List<Map<String, dynamic>>.from(res); _loadingIssues = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingIssues = false);
    }
  }

  Future<void> _toggleTask(String taskId, String currentStatus) async {
    final newStatus = currentStatus == 'done' ? 'todo' : 'done';
    await _client.from('tasks').update({'status': newStatus}).eq('id', taskId);
    _loadTasks();
  }

  Future<void> _updateIssueStatus(String issueId, String newStatus) async {
    await _client.from('issues').update({'status': newStatus}).eq('id', issueId);
    _loadIssues();
  }

  List<Map<String, dynamic>> get _filteredTasks {
    if (_taskFilter == 'all') return _tasks;
    return _tasks.where((t) => t['status'] == _taskFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Tab bar
      TabBar(
        controller: _tabController,
        tabs: [
          Tab(text: 'Tasks (${_tasks.length})'),
          Tab(text: 'Issues (${_issues.length})'),
        ],
      ),
      Expanded(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTasksTab(),
            _buildIssuesTab(),
          ],
        ),
      ),
    ]);
  }

  Widget _buildTasksTab() {
    if (_loadingTasks) return const Center(child: CircularProgressIndicator());

    return Column(children: [
      // Filter chips
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          for (final filter in ['all', 'todo', 'in_progress', 'done'])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter.replaceAll('_', ' ')),
                selected: _taskFilter == filter,
                onSelected: (_) => setState(() => _taskFilter = filter),
              ),
            ),
        ]),
      ),
      // Tasks list
      Expanded(
        child: _filteredTasks.isEmpty
            ? const Center(child: Text('No tasks', style: TextStyle(color: Colors.grey)))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _filteredTasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final task = _filteredTasks[i];
                  final isDone = task['status'] == 'done';
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(children: [
                      GestureDetector(
                        onTap: () => _toggleTask(task['id'], task['status']),
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
                          child: isDone ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(task['title'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                              color: isDone ? Colors.grey : Colors.black,
                            )),
                        if (task['due_date'] != null)
                          Text('Due: ${task['due_date'].toString().substring(0, 10)}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ])),
                      _PriorityBadge(priority: task['priority'] ?? 'medium'),
                    ]),
                  );
                },
              ),
      ),
    ]);
  }

  Widget _buildIssuesTab() {
    if (_loadingIssues) return const Center(child: CircularProgressIndicator());
    if (_issues.isEmpty) return const Center(child: Text('No issues', style: TextStyle(color: Colors.grey)));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _issues.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final issue = _issues[i];
        final status = issue['status'] ?? 'open';
        final statusColor = _issueStatusColor(status);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(issue['title'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w500))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(status.replaceAll('_', ' '),
                    style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w500)),
              ),
            ]),
            if (issue['description'] != null && issue['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(issue['description'], style: const TextStyle(fontSize: 13, color: Colors.grey),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            // Status actions
            if (status == 'open')
              TextButton(
                onPressed: () => _updateIssueStatus(issue['id'], 'in_progress'),
                style: TextButton.styleFrom(minimumSize: Size.zero, padding: EdgeInsets.zero),
                child: const Text('Mark In Progress', style: TextStyle(fontSize: 12)),
              ),
            if (status == 'in_progress')
              TextButton(
                onPressed: () => _updateIssueStatus(issue['id'], 'resolved'),
                style: TextButton.styleFrom(minimumSize: Size.zero, padding: EdgeInsets.zero),
                child: const Text('Mark Resolved', style: TextStyle(fontSize: 12)),
              ),
          ]),
        );
      },
    );
  }

  Color _issueStatusColor(String status) {
    switch (status) {
      case 'open': return Colors.red;
      case 'in_progress': return Colors.blue;
      case 'resolved': return Colors.green;
      case 'closed': return Colors.grey;
      default: return Colors.grey;
    }
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      'critical' => Colors.red,
      'high' => Colors.orange,
      'low' => Colors.green,
      _ => Colors.blue,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(priority, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}
