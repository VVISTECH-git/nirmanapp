// lib/screens/daily_log/daily_log_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../services/supabase_service.dart';

class DailyLogFormScreen extends ConsumerStatefulWidget {
  const DailyLogFormScreen({super.key});
  @override
  ConsumerState<DailyLogFormScreen> createState() => _DailyLogFormScreenState();
}

class _DailyLogFormScreenState extends ConsumerState<DailyLogFormScreen> {
  final _summaryCtrl = TextEditingController();
  final _materialsCtrl = TextEditingController();
  final _issuesCtrl = TextEditingController();
  final _nextDayCtrl = TextEditingController();
  int _workers = 0;
  String _weather = 'Sunny';
  bool _loading = false;

  final _weathers = ['Sunny', 'Cloudy', 'Rainy', 'Hot', 'Windy'];

  @override
  Widget build(BuildContext context) {
    final projectId = ref.watch(selectedProjectIdProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Log for ${_today()}'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weather & Workers
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFEEEEEE))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Weather', style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                        const SizedBox(height: 8),
                        DropdownButton<String>(
                          value: _weather,
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          items: _weathers.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                          onChanged: (v) => setState(() => _weather = v!),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFEEEEEE))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Workers present', style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _workers = (_workers - 1).clamp(0, 100)),
                              child: Container(
                                width: 30, height: 30,
                                decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(6)),
                                child: const Icon(Icons.remove, size: 16),
                              ),
                            ),
                            Text('$_workers', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                            GestureDetector(
                              onTap: () => setState(() => _workers++),
                              child: Container(
                                width: 30, height: 30,
                                decoration: BoxDecoration(color: const Color(0xFF378ADD), borderRadius: BorderRadius.circular(6)),
                                child: const Icon(Icons.add, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _LogField(controller: _summaryCtrl, label: 'Work done today', hint: 'What was accomplished today?', maxLines: 4, required: true),
            const SizedBox(height: 12),
            _LogField(controller: _materialsCtrl, label: 'Materials used', hint: 'Cement bags, steel rods, bricks...', maxLines: 3),
            const SizedBox(height: 12),
            _LogField(controller: _issuesCtrl, label: 'Issues noticed', hint: 'Any problems, delays, or concerns?', maxLines: 3),
            const SizedBox(height: 12),
            _LogField(controller: _nextDayCtrl, label: 'Plan for tomorrow', hint: 'What should happen next?', maxLines: 3),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : () => _submit(projectId!),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save daily log', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _submit(String projectId) async {
    if (_summaryCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add work summary')));
      return;
    }
    setState(() => _loading = true);
    try {
      await SupabaseService.upsertDailyLog({
        'project_id': projectId,
        'log_date': DateTime.now().toIso8601String().substring(0, 10),
        'weather': _weather,
        'workers_present': _workers,
        'work_summary': _summaryCtrl.text.trim(),
        'materials_used': _materialsCtrl.text.trim().isEmpty ? null : _materialsCtrl.text.trim(),
        'issues_noted': _issuesCtrl.text.trim().isEmpty ? null : _issuesCtrl.text.trim(),
        'next_day_plan': _nextDayCtrl.text.trim().isEmpty ? null : _nextDayCtrl.text.trim(),
      });
      ref.invalidate(todayLogProvider(projectId));
      ref.invalidate(dailyLogsProvider(projectId));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _today() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

class _LogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final bool required;

  const _LogField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 3,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            if (required) const Text(' *', style: TextStyle(color: Color(0xFFE24B4A))),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
