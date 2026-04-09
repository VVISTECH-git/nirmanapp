import 'add_expense_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MoneyScreen extends StatefulWidget {
  final Map<String, dynamic> project;
  const MoneyScreen({super.key, required this.project});

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> with SingleTickerProviderStateMixin {
  final _client = Supabase.instance.client;
  late TabController _tabController;
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _payments = [];
  bool _loadingExpenses = true;
  bool _loadingPayments = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExpenses();
    _loadPayments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    try {
      final res = await _client
          .from('expenses')
          .select()
          .eq('project_id', widget.project['id'])
          .order('expense_date', ascending: false);
      if (mounted) setState(() { _expenses = List<Map<String, dynamic>>.from(res); _loadingExpenses = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingExpenses = false);
    }
  }

  Future<void> _loadPayments() async {
    try {
      final res = await _client
          .from('payments')
          .select()
          .eq('project_id', widget.project['id'])
          .order('due_date', ascending: true);
      if (mounted) setState(() { _payments = List<Map<String, dynamic>>.from(res); _loadingPayments = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingPayments = false);
    }
  }

  Future<void> _markPaymentPaid(String paymentId) async {
    await _client.from('payments').update({
      'status': 'paid',
      'paid_date': DateTime.now().toIso8601String().substring(0, 10),
    }).eq('id', paymentId);
    _loadPayments();
  }

  int get _totalExpenses => _expenses.fold(0, (sum, e) =>
      sum + ((e['amount_paise'] ?? 0) as num).toInt() + ((e['gst_paise'] ?? 0) as num).toInt());

  Map<String, int> get _categoryTotals {
    final Map<String, int> totals = {};
    for (final e in _expenses) {
      final cat = e['category'] ?? 'misc';
      totals[cat] = (totals[cat] ?? 0) +
          ((e['amount_paise'] ?? 0) as num).toInt() +
          ((e['gst_paise'] ?? 0) as num).toInt();
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TabBar(
        controller: _tabController,
        tabs: [
          Tab(text: 'Expenses (${_expenses.length})'),
          Tab(text: 'Payments (${_payments.length})'),
        ],
      ),
      Expanded(
        child: TabBarView(
          controller: _tabController,
          children: [_buildExpensesTab(), _buildPaymentsTab()],
        ),
      ),
    ]);
  }

  Widget _buildExpensesTab() {
    if (_loadingExpenses) return const Center(child: CircularProgressIndicator());

    final budgetPaise = (widget.project['total_budget_paise'] ?? 0) as num;
    final spentPct = budgetPaise > 0 ? (_totalExpenses / budgetPaise).clamp(0.0, 1.0) : 0.0;

    return Stack(children: [
      ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Budget Summary', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _SummaryItem(label: 'Budget', value: '₹${(budgetPaise / 10000000).toStringAsFixed(1)}L'),
              _SummaryItem(label: 'Spent', value: '₹${(_totalExpenses / 10000000).toStringAsFixed(1)}L'),
              _SummaryItem(
                label: 'Remaining',
                value: '₹${((budgetPaise - _totalExpenses) / 10000000).toStringAsFixed(1)}L',
                color: Colors.green,
              ),
            ]),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: spentPct.toDouble(), minHeight: 8,
                borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: 4),
            Text('${(spentPct * 100).round()}% of budget used',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
        ),
        const SizedBox(height: 16),

        // Category breakdown
        if (_categoryTotals.isNotEmpty) ...[
          const Text('By Category', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: _categoryTotals.entries.map((e) {
                final pct = budgetPaise > 0 ? (e.value / budgetPaise).clamp(0.0, 1.0) : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    SizedBox(width: 110, child: Text(e.key, style: const TextStyle(fontSize: 13))),
                    Expanded(child: LinearProgressIndicator(
                      value: pct.toDouble(), minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    )),
                    const SizedBox(width: 8),
                    Text('₹${(e.value / 100000).toStringAsFixed(0)}K',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ]),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Expenses list
        const Text('All Expenses', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ..._expenses.map((e) {
          final total = ((e['amount_paise'] ?? 0) as num).toInt() +
              ((e['gst_paise'] ?? 0) as num).toInt();
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(e['expense_date']?.toString().substring(0, 10) ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('₹${(total / 100000).toStringAsFixed(1)}K',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(e['category'] ?? '',
                      style: const TextStyle(fontSize: 10, color: Colors.blue)),
                ),
              ]),
            ]),
          );
        }),
      ],
    ),
      Positioned(
        bottom: 16, right: 16,
        child: FloatingActionButton.extended(
          heroTag: 'add_expense',
          onPressed: () async {
            final added = await Navigator.push(context, MaterialPageRoute(
              builder: (_) => AddExpenseScreen(projectId: widget.project['id'])));
            if (added == true) { _loadExpenses(); }
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Expense'),
        ),
      ),
    ]);
  }

  Widget _buildPaymentsTab() {
    if (_loadingPayments) return const Center(child: CircularProgressIndicator());
    if (_payments.isEmpty) return const Center(child: Text('No payments', style: TextStyle(color: Colors.grey)));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _payments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final p = _payments[i];
        final isPaid = p['status'] == 'paid';
        final amount = ((p['amount_paise'] ?? 0) as num).toInt();

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(p['title'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w500))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPaid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(isPaid ? 'paid' : 'pending',
                    style: TextStyle(
                      fontSize: 11,
                      color: isPaid ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    )),
              ),
            ]),
            const SizedBox(height: 4),
            Text('₹${(amount / 10000000).toStringAsFixed(2)}L',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
            if (p['milestone_description'] != null) ...[
              const SizedBox(height: 4),
              Text(p['milestone_description'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
            Text('Due: ${p['due_date']?.toString().substring(0, 10) ?? '-'}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (!isPaid) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _markPaymentPaid(p['id']),
                  child: const Text('Mark as Paid'),
                ),
              ),
            ],
          ]),
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _SummaryItem({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ]);
  }
}
