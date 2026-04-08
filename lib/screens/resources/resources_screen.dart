// lib/screens/resources/resources_screen.dart
import 'package:flutter/material.dart' hide Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';

class ResourcesScreen extends ConsumerStatefulWidget {
  const ResourcesScreen({super.key});
  @override
  ConsumerState<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends ConsumerState<ResourcesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final projectId = ref.watch(selectedProjectIdProvider);
    if (projectId == null) return const LoadingScreen();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Resources'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [Tab(text: 'Contractors & workers'), Tab(text: 'Materials')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _ContractorsTab(projectId: projectId),
          _MaterialsTab(projectId: projectId),
        ],
      ),
      floatingActionButton: NirmanFAB(
        onTap: () => _tabCtrl.index == 0
            ? _showAddContractor(context, projectId)
            : _showAddMaterial(context, projectId),
        label: _tabCtrl.index == 0 ? 'Add contractor' : 'Add material',
      ),
    );
  }

  void _showAddContractor(BuildContext context, String projectId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _AddContractorSheet(projectId: projectId, ref: ref),
    );
  }

  void _showAddMaterial(BuildContext context, String projectId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _AddMaterialSheet(projectId: projectId, ref: ref),
    );
  }
}

class _ContractorsTab extends ConsumerWidget {
  final String projectId;
  const _ContractorsTab({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractorsAsync = ref.watch(contractorsProvider(projectId));

    return contractorsAsync.when(
      loading: () => const LoadingScreen(),
      error: (e, _) => Center(child: Text('$e')),
      data: (contractors) {
        if (contractors.isEmpty) {
          return const EmptyState(
            title: 'No contractors yet',
            subtitle: 'Add your mason, plumber, electrician and other contractors',
            icon: Icons.people_outline,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: contractors.length,
          itemBuilder: (_, i) => _ContractorCard(contractor: contractors[i]),
        );
      },
    );
  }
}

class _ContractorCard extends StatelessWidget {
  final Contractor contractor;
  const _ContractorCard({required this.contractor});

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
      child: Row(
        children: [
          UserAvatar(initials: contractor.initials, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contractor.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                if (contractor.role != null)
                  Text(contractor.role!, style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (contractor.phone != null) ...[
                      const Icon(Icons.phone, size: 12, color: Color(0xFF9E9E9E)),
                      const SizedBox(width: 3),
                      Text(contractor.phone!, style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                      const SizedBox(width: 10),
                    ],
                    if (contractor.dailyRatePaise > 0) ...[
                      Text(formatRupees(contractor.dailyRatePaise), style: const TextStyle(fontSize: 12, color: Color(0xFF1D9E75), fontWeight: FontWeight.w500)),
                      const Text('/day', style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                    ],
                  ],
                ),
                if (contractor.contractAmountPaise > 0) ...[
                  const SizedBox(height: 2),
                  Text('Contract: ${formatRupees(contractor.contractAmountPaise, compact: true)}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: contractor.isActive ? const Color(0xFFEAF3DE) : const Color(0xFFF1EFE8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              contractor.isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: contractor.isActive ? const Color(0xFF3B6D11) : const Color(0xFF5F5E5A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialsTab extends ConsumerWidget {
  final String projectId;
  const _MaterialsTab({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(materialsProvider(projectId));

    return materialsAsync.when(
      loading: () => const LoadingScreen(),
      error: (e, _) => Center(child: Text('$e')),
      data: (materials) {
        if (materials.isEmpty) {
          return const EmptyState(
            title: 'No materials logged',
            subtitle: 'Track cement, steel, bricks and other materials',
            icon: Icons.inventory_2_outlined,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: materials.length,
          itemBuilder: (_, i) => _MaterialCard(material: materials[i]),
        );
      },
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final Material material;
  const _MaterialCard({required this.material});

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
                Text(
                  material.name + (material.brand != null ? ' – ${material.brand}' : ''),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (material.quantity != null && material.unit != null) ...[
                      Text('${material.quantity} ${material.unit}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
                      const SizedBox(width: 8),
                    ],
                    if (material.deliveryDate != null) ...[
                      const Icon(Icons.local_shipping_outlined, size: 12, color: Color(0xFF9E9E9E)),
                      const SizedBox(width: 3),
                      Text(
                        '${material.deliveryDate!.day}/${material.deliveryDate!.month}/${material.deliveryDate!.year}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
                      ),
                    ],
                  ],
                ),
                if (material.supplier != null)
                  Text(material.supplier!, style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
              ],
            ),
          ),
          Text(
            formatRupees(material.totalPricePaise, compact: true),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// Add Contractor Sheet
class _AddContractorSheet extends StatefulWidget {
  final String projectId;
  final WidgetRef ref;
  const _AddContractorSheet({required this.projectId, required this.ref});

  @override
  State<_AddContractorSheet> createState() => _AddContractorSheetState();
}

class _AddContractorSheetState extends State<_AddContractorSheet> {
  final _nameCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _contractCtrl = TextEditingController();
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
            const Text('Add contractor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name *')),
            const SizedBox(height: 10),
            TextField(controller: _roleCtrl, decoration: const InputDecoration(labelText: 'Role', hintText: 'e.g. Mason, Plumber, Electrician')),
            const SizedBox(height: 10),
            TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number')),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(controller: _rateCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Daily rate (₹)', prefixText: '₹ '))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _contractCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Contract amount (₹)', prefixText: '₹ '))),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Add contractor'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await SupabaseService.createContractor({
        'project_id': widget.projectId,
        'name': _nameCtrl.text.trim(),
        'role': _roleCtrl.text.trim().isEmpty ? null : _roleCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'daily_rate_paise': _rateCtrl.text.isEmpty ? 0 : (double.parse(_rateCtrl.text) * 100).round(),
        'contract_amount_paise': _contractCtrl.text.isEmpty ? 0 : (double.parse(_contractCtrl.text) * 100).round(),
        'is_active': true,
      });
      widget.ref.invalidate(contractorsProvider(widget.projectId));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// Add Material Sheet
class _AddMaterialSheet extends StatefulWidget {
  final String projectId;
  final WidgetRef ref;
  const _AddMaterialSheet({required this.projectId, required this.ref});

  @override
  State<_AddMaterialSheet> createState() => _AddMaterialSheetState();
}

class _AddMaterialSheetState extends State<_AddMaterialSheet> {
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  DateTime? _deliveryDate;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add material', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Material *', hintText: 'e.g. Cement'))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _brandCtrl, decoration: const InputDecoration(labelText: 'Brand', hintText: 'e.g. ACC'))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: _qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity'))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _unitCtrl, decoration: const InputDecoration(labelText: 'Unit', hintText: 'bags, tons, pieces'))),
            ]),
            const SizedBox(height: 10),
            TextField(controller: _priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total price (₹)', prefixText: '₹ ')),
            const SizedBox(height: 10),
            TextField(controller: _supplierCtrl, decoration: const InputDecoration(labelText: 'Supplier')),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (d != null) setState(() => _deliveryDate = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE0E0E0))),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Color(0xFF9E9E9E)),
                    const SizedBox(width: 8),
                    Text(
                      _deliveryDate != null ? 'Delivery: ${_deliveryDate!.day}/${_deliveryDate!.month}/${_deliveryDate!.year}' : 'Delivery date',
                      style: TextStyle(color: _deliveryDate != null ? const Color(0xFF1A1A1A) : const Color(0xFFAAAAAA), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Add material'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final price = _priceCtrl.text.isEmpty ? 0 : (double.parse(_priceCtrl.text) * 100).round();
      final qty = _qtyCtrl.text.isEmpty ? null : double.parse(_qtyCtrl.text);
      await SupabaseService.createMaterial({
        'project_id': widget.projectId,
        'name': _nameCtrl.text.trim(),
        'brand': _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
        'quantity': qty,
        'unit': _unitCtrl.text.trim().isEmpty ? null : _unitCtrl.text.trim(),
        'total_price_paise': price,
        'supplier': _supplierCtrl.text.trim().isEmpty ? null : _supplierCtrl.text.trim(),
        'delivery_date': _deliveryDate?.toIso8601String().substring(0, 10),
      });
      widget.ref.invalidate(materialsProvider(widget.projectId));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
