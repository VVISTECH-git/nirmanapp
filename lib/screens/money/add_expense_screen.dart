import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddExpenseScreen extends StatefulWidget {
  final String projectId;
  const AddExpenseScreen({super.key, required this.projectId});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _client = Supabase.instance.client;
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  String _category = 'materials';
  String? _selectedPhaseId;
  List<Map<String, dynamic>> _phases = [];
  DateTime _date = DateTime.now();
  bool _saving = false;

  final _categories = ['materials', 'labour', 'equipment', 'professional_fees', 'approvals', 'misc'];

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
    if (_titleCtrl.text.trim().isEmpty || _amountCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final amount = (double.tryParse(_amountCtrl.text.trim()) ?? 0) * 100; // rupees to paise
      final gst = (double.tryParse(_gstCtrl.text.trim()) ?? 0) * 100;
      await _client.from('expenses').insert({
        'project_id': widget.projectId,
        'phase_id': _selectedPhaseId,
        'title': _titleCtrl.text.trim(),
        'category': _category,
        'amount_paise': amount.toInt(),
        'gst_paise': gst.toInt(),
        'expense_date': _date.toIso8601String().substring(0, 10),
        'paid_by': _client.auth.currentUser!.id,
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
        title: const Text('Add Expense'),
        actions: [TextButton(onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder())),
          const SizedBox(height: 16),

          Row(children: [
            Expanded(child: TextField(controller: _amountCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (₹) *', border: OutlineInputBorder(), prefixText: '₹'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _gstCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'GST (₹)', border: OutlineInputBorder(), prefixText: '₹'))),
          ]),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
            value: _category,
            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.replaceAll('_', ' ')))).toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Phase', border: OutlineInputBorder()),
            value: _selectedPhaseId,
            items: [const DropdownMenuItem(value: null, child: Text('No phase')),
              ..._phases.map((p) => DropdownMenuItem(value: p['id'] as String, child: Text(p['name'] ?? '')))],
            onChanged: (v) => setState(() => _selectedPhaseId = v),
          ),
          const SizedBox(height: 16),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Date: ${_date.toIso8601String().substring(0, 10)}'),
            leading: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final d = await showDatePicker(context: context,
                initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
              if (d != null) setState(() => _date = d);
            },
          ),
        ]),
      ),
    );
  }
}
