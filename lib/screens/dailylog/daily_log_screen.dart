import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyLogScreen extends StatefulWidget {
  final String projectId;
  const DailyLogScreen({super.key, required this.projectId});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final res = await _client
          .from('daily_logs')
          .select()
          .eq('project_id', widget.projectId)
          .order('log_date', ascending: false)
          .limit(30);
      if (mounted) setState(() { _logs = List<Map<String, dynamic>>.from(res); _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: _logs.isEmpty
          ? const Center(child: Text('No daily logs yet', style: TextStyle(color: Colors.grey)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _LogCard(log: _logs[i]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => AddDailyLogScreen(projectId: widget.projectId),
          ));
          _loadLogs();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Log'),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(log['log_date']?.toString().substring(0, 10) ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(width: 10),
          if (log['weather'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(log['weather'], style: const TextStyle(fontSize: 11, color: Colors.blue)),
            ),
          const Spacer(),
          if (log['workers_present'] != null)
            Row(children: [
              const Icon(Icons.people_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text('${log['workers_present']} workers',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
        ]),
        if (log['work_summary'] != null) ...[
          const SizedBox(height: 8),
          Text(log['work_summary'], style: const TextStyle(fontSize: 13)),
        ],
        if (log['materials_used'] != null) ...[
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Materials: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
            Expanded(child: Text(log['materials_used'], style: const TextStyle(fontSize: 12, color: Colors.grey))),
          ]),
        ],
        if (log['issues_noted'] != null) ...[
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Issues: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.orange)),
            Expanded(child: Text(log['issues_noted'], style: const TextStyle(fontSize: 12, color: Colors.orange))),
          ]),
        ],
        if (log['next_day_plan'] != null) ...[
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Tomorrow: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.green)),
            Expanded(child: Text(log['next_day_plan'], style: const TextStyle(fontSize: 12, color: Colors.green))),
          ]),
        ],
      ]),
    );
  }
}

class AddDailyLogScreen extends StatefulWidget {
  final String projectId;
  const AddDailyLogScreen({super.key, required this.projectId});

  @override
  State<AddDailyLogScreen> createState() => _AddDailyLogScreenState();
}

class _AddDailyLogScreenState extends State<AddDailyLogScreen> {
  final _client = Supabase.instance.client;
  final _summaryCtrl = TextEditingController();
  final _materialsCtrl = TextEditingController();
  final _issuesCtrl = TextEditingController();
  final _tomorrowCtrl = TextEditingController();
  final _workersCtrl = TextEditingController();
  String _weather = 'Sunny';
  bool _saving = false;

  final _weatherOptions = ['Sunny', 'Cloudy', 'Rainy', 'Hot', 'Windy'];

  Future<void> _save() async {
    if (_summaryCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await _client.from('daily_logs').upsert({
        'project_id': widget.projectId,
        'log_date': today,
        'logged_by': _client.auth.currentUser!.id,
        'weather': _weather,
        'workers_present': int.tryParse(_workersCtrl.text.trim()) ?? 0,
        'work_summary': _summaryCtrl.text.trim(),
        'materials_used': _materialsCtrl.text.trim().isEmpty ? null : _materialsCtrl.text.trim(),
        'issues_noted': _issuesCtrl.text.trim().isEmpty ? null : _issuesCtrl.text.trim(),
        'next_day_plan': _tomorrowCtrl.text.trim().isEmpty ? null : _tomorrowCtrl.text.trim(),
      }, onConflict: 'project_id,log_date');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Today's Log — ${DateTime.now().toIso8601String().substring(0, 10)}"),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Weather
          const Text('Weather', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _weatherOptions.map((w) => ChoiceChip(
              label: Text(w),
              selected: _weather == w,
              onSelected: (_) => setState(() => _weather = w),
            )).toList(),
          ),
          const SizedBox(height: 16),

          // Workers
          TextField(
            controller: _workersCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Workers Present',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Work summary
          TextField(
            controller: _summaryCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Work Summary *',
              border: OutlineInputBorder(),
              hintText: 'What was done today?',
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _materialsCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Materials Used',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _issuesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Issues Noted',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _tomorrowCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: "Tomorrow's Plan",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}
