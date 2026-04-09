import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddTaskScreen extends StatefulWidget {
  final String projectId;
  const AddTaskScreen({super.key, required this.projectId});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _client = Supabase.instance.client;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'medium';
  String? _selectedPhaseId;
  List<Map<String, dynamic>> _phases = [];
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPhases();
  }

  Future<void> _loadPhases() async {
    final res = await _client.from('phases').select('id, name').eq('project_id', widget.projectId).order('order_index');
    if (mounted) setState(() => _phases = List<Map<String, dynamic>>.from(res));
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await _client.from('tasks').insert({
        'project_id': widget.projectId,
        'phase_id': _selectedPhaseId,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'priority': _priority,
        'status': 'todo',
        'due_date': _dueDate?.toIso8601String().substring(0, 10),
        'created_by': _client.auth.currentUser!.id,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Task'),
        actions: [TextButton(onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Task Title *', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _descCtrl, maxLines: 2,
            decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
          const SizedBox(height: 16),

          // Phase dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Phase', border: OutlineInputBorder()),
            value: _selectedPhaseId,
            items: _phases.map((p) => DropdownMenuItem(value: p['id'] as String, child: Text(p['name'] ?? ''))).toList(),
            onChanged: (v) => setState(() => _selectedPhaseId = v),
          ),
          const SizedBox(height: 16),

          // Priority
          const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: ['low', 'medium', 'high', 'critical'].map((p) =>
            ChoiceChip(label: Text(p), selected: _priority == p,
              onSelected: (_) => setState(() => _priority = p))).toList()),
          const SizedBox(height: 16),

          // Due date
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_dueDate == null ? 'Set Due Date' : 'Due: ${_dueDate!.toIso8601String().substring(0, 10)}'),
            leading: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final d = await showDatePicker(context: context,
                initialDate: DateTime.now(), firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)));
              if (d != null) setState(() => _dueDate = d);
            },
          ),
        ]),
      ),
    );
  }
}
