import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResourcesScreen extends StatefulWidget {
  final String projectId;
  const ResourcesScreen({super.key, required this.projectId});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> with SingleTickerProviderStateMixin {
  final _client = Supabase.instance.client;
  late TabController _tabController;
  List<Map<String, dynamic>> _contractors = [];
  List<Map<String, dynamic>> _materials = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _load() async {
    final c = await _client.from('contractors').select().eq('project_id', widget.projectId).order('name');
    final m = await _client.from('materials').select().eq('project_id', widget.projectId).order('delivery_date', ascending: false);
    if (mounted) setState(() { _contractors = List<Map<String, dynamic>>.from(c); _materials = List<Map<String, dynamic>>.from(m); _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Column(children: [
      TabBar(controller: _tabController, tabs: [
        Tab(text: 'Contractors (${_contractors.length})'),
        Tab(text: 'Materials (${_materials.length})'),
      ]),
      Expanded(child: TabBarView(controller: _tabController, children: [
        _buildContractors(),
        _buildMaterials(),
      ])),
    ]);
  }

  Widget _buildContractors() {
    if (_contractors.isEmpty) return const Center(child: Text('No contractors', style: TextStyle(color: Colors.grey)));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _contractors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final c = _contractors[i];
        final isActive = c['is_active'] == true;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
          child: Row(children: [
            CircleAvatar(backgroundColor: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              child: Text((c['name'] ?? '?')[0].toUpperCase(), style: TextStyle(color: isActive ? Colors.green : Colors.grey, fontWeight: FontWeight.bold))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(c['role'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              if (c['phone'] != null) Text(c['phone'], style: const TextStyle(fontSize: 12, color: Colors.blue)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Text(isActive ? 'active' : 'inactive', style: TextStyle(fontSize: 11, color: isActive ? Colors.green : Colors.grey)),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildMaterials() {
    if (_materials.isEmpty) return const Center(child: Text('No materials', style: TextStyle(color: Colors.grey)));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _materials.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final m = _materials[i];
        final total = ((m['total_price_paise'] ?? 0) as num).toInt();
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.inventory_2_outlined, color: Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
              if (m['brand'] != null) Text(m['brand'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text('${m['quantity']} ${m['unit'] ?? ''} · ${m['supplier'] ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('₹${(total / 100000).toStringAsFixed(0)}K', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(m['delivery_date']?.toString().substring(0, 10) ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          ]),
        );
      },
    );
  }
}
