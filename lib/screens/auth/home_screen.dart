import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dashboard/dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _projects = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final res = await _client.from('project_summary').select();
      if (mounted) {
        setState(() {
          _projects = List<Map<String, dynamic>>.from(res);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NirmanApp'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async => await _client.auth.signOut(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : _projects.isEmpty
                  ? const Center(child: Text('No projects found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _projects.length,
                      itemBuilder: (_, i) {
                        final p = _projects[i];
                        final budget = (p['total_budget_paise'] ?? 0) / 10000000;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(p['name'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('Budget: ₹${budget.toStringAsFixed(1)}L'),
                            trailing: Text('${p['open_tasks'] ?? 0} tasks'),
                            onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                builder: (_) => DashboardScreen(project: p))),
                          ),
                        );
                      },
                    ),
    );
  }
}
