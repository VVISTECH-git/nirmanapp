// lib/screens/expenses/expenses_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../../config/app_config.dart';
import '../../services/supabase_service.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = ref.watch(selectedProjectIdProvider);
    if (projectId == null) return const LoadingScreen();

    final expensesAsync = ref.watch(expensesProvider(projectId));
    final summaryAsync = ref.watch(expenseSummaryProvider(projectId));
    final projectAsync = ref.watch(selectedProjectProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('Money'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Expenses'), Tab(text: 'Payments')],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push('/expenses/add'),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Expenses tab
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Budget summary
                        projectAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (project) => project != null ? _BudgetSummary(project: project) : const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 16),
                        // Category breakdown
                        const SectionHeader('By category'),
                        summaryAsync.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (summary) => _CategoryBreakdown(summary: summary),
                        ),
                        const SizedBox(height: 16),
                        SectionHeader('All expenses', action: 'Add', onAction: () => context.push('/expenses/add')),
                      ],
                    ),
                  ),
                ),
                expensesAsync.when(
                  loading: () => const SliverToBoxAdapter(child: LoadingScreen()),
                  error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('$e'))),
                  data: (expenses) {
                    if (expenses.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: EmptyState(
                          title: 'No expenses yet',
                          subtitle: 'Track your construction spending here',
                          icon: Icons.receipt_long_outlined,
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _ExpenseCard(expense: expenses[i]),
                        ),
                        childCount: expenses.length,
                      ),
                    );
                  },
                ),
              ],
            ),
            // Payments tab - delegate to payments screen
            const _PaymentsTabView(),
          ],
        ),
        floatingActionButton: NirmanFAB(
          onTap: () => context.push('/expenses/add'),
          label: 'Add expense',
        ),
      ),
    );
  }
}

class _BudgetSummary extends StatelessWidget {
  final Project project;
  const _BudgetSummary({required this.project});

  @override
  Widget build(BuildContext context) {
    final pct = project.progressPercent;
    final remaining = project.totalBudgetPaise - (project.totalSpentPaise ?? 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _budgetItem('Total budget', formatRupees(project.totalBudgetPaise, compact: true), const Color(0xFF1A1A1A))),
              Expanded(child: _budgetItem('Spent', formatRupees(project.totalSpentPaise ?? 0, compact: true), const Color(0xFFE24B4A))),
              Expanded(child: _budgetItem('Remaining', formatRupees(remaining > 0 ? remaining : 0, compact: true), const Color(0xFF1D9E75))),
            ],
          ),
          const SizedBox(height: 12),
          NirmanProgressBar(
            progress: pct,
            color: pct > 90 ? const Color(0xFFE24B4A) : pct > 75 ? const Color(0xFFEF9F27) : const Color(0xFF1D9E75),
            height: 8,
          ),
          const SizedBox(height: 6),
          Text('${pct.toStringAsFixed(0)}% of budget used',
              style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
        ],
      ),
    );
  }

  Widget _budgetItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final Map<String, int> summary;
  const _CategoryBreakdown({required this.summary});

  static const _catColors = {
    'materials': Color(0xFF378ADD),
    'labour': Color(0xFF7F77DD),
    'equipment': Color(0xFF1D9E75),
    'professional_fees': Color(0xFFD85A30),
    'approvals': Color(0xFFEF9F27),
    'misc': Color(0xFF888780),
  };

  @override
  Widget build(BuildContext context) {
    final total = summary.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    return Column(
      children: summary.entries.map((e) {
        final pct = total > 0 ? e.value / total * 100 : 0.0;
        final color = _catColors[e.key] ?? const Color(0xFF9E9E9E);
        final label = AppStrings.expenseCategoryLabels[e.key] ?? e.key;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Text(formatRupees(e.value, compact: true), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 6),
              NirmanProgressBar(progress: pct.toDouble(), color: color, height: 4),
              const SizedBox(height: 3),
              Align(
                alignment: Alignment.centerRight,
                child: Text('${pct.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  const _ExpenseCard({required this.expense});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1EFE8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AppStrings.expenseCategoryLabels[expense.category] ?? expense.category,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF5F5E5A)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${expense.expenseDate.day}/${expense.expenseDate.month}/${expense.expenseDate.year}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
                    ),
                  ],
                ),
                if (expense.gstPaise > 0) ...[
                  const SizedBox(height: 2),
                  Text('GST: ${formatRupees(expense.gstPaise)}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatRupees(expense.totalPaise),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
              if (expense.receiptUrl != null)
                const Icon(Icons.attach_file, size: 14, color: Color(0xFF9E9E9E)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentsTabView extends ConsumerWidget {
  const _PaymentsTabView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = ref.watch(selectedProjectIdProvider);
    if (projectId == null) return const SizedBox.shrink();

    final paymentsAsync = ref.watch(paymentsProvider(projectId));

    return paymentsAsync.when(
      loading: () => const LoadingScreen(),
      error: (e, _) => Center(child: Text('$e')),
      data: (payments) {
        if (payments.isEmpty) {
          return EmptyState(
            title: 'No payments yet',
            subtitle: 'Track milestone-based contractor payments',
            icon: Icons.payments_outlined,
            buttonLabel: 'Add payment',
            onButton: () {},
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          itemBuilder: (_, i) => _PaymentCard(payment: payments[i], ref: ref, projectId: projectId),
        );
      },
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Payment payment;
  final WidgetRef ref;
  final String projectId;

  const _PaymentCard({required this.payment, required this.ref, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(payment.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
              StatusBadge(payment.status),
            ],
          ),
          if (payment.contractorName != null) ...[
            const SizedBox(height: 3),
            Text(payment.contractorName!, style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
          ],
          if (payment.milestoneDescription != null) ...[
            const SizedBox(height: 4),
            Text(payment.milestoneDescription!,
                style: const TextStyle(fontSize: 12, color: Color(0xFF666666), fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatRupees(payment.amountPaise),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              if (payment.status == 'pending')
                ElevatedButton(
                  onPressed: () => _markPaid(context, ref, projectId),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Mark paid', style: TextStyle(fontSize: 12)),
                ),
              if (payment.paidDate != null)
                Text(
                  'Paid ${payment.paidDate!.day}/${payment.paidDate!.month}/${payment.paidDate!.year}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF1D9E75)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _markPaid(BuildContext context, WidgetRef ref, String projectId) async {
    await SupabaseService.markPaymentPaid(payment.id);
    ref.invalidate(paymentsProvider(projectId));
  }
}
