// lib/screens/dashboard/create_project_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../services/supabase_service.dart';

class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});
  @override
  ConsumerState<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('New project'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Project details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Set up your house construction project', style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
            const SizedBox(height: 24),

            _label('Project name *'),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'e.g. My house – Kompally')),
            const SizedBox(height: 16),

            _label('Site address'),
            TextField(controller: _addressCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'Plot no, street, area')),
            const SizedBox(height: 16),

            _label('City'),
            TextField(controller: _cityCtrl, decoration: const InputDecoration(hintText: 'e.g. Hyderabad')),
            const SizedBox(height: 16),

            _label('Total budget (₹)'),
            TextField(
              controller: _budgetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'e.g. 2500000', prefixText: '₹ '),
            ),
            const SizedBox(height: 16),

            _label('Start date'),
            _datePicker(
              value: _startDate,
              hint: 'Select start date',
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                if (d != null) setState(() => _startDate = d);
              },
            ),
            const SizedBox(height: 16),

            _label('Expected completion'),
            _datePicker(
              value: _endDate,
              hint: 'Select end date',
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 365)), firstDate: DateTime.now(), lastDate: DateTime(2030));
                if (d != null) setState(() => _endDate = d);
              },
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F1FB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF185FA5), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Default phases will be created automatically: Planning, Foundation, Structure, Roofing, Plumbing & Electrical, Finishing.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF185FA5)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create project', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
  );

  Widget _datePicker({required DateTime? value, required String hint, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: Color(0xFF9E9E9E)),
            const SizedBox(width: 10),
            Text(
              value != null ? '${value.day}/${value.month}/${value.year}' : hint,
              style: TextStyle(color: value != null ? const Color(0xFF1A1A1A) : const Color(0xFFAAAAAA), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a project name')));
      return;
    }
    setState(() => _loading = true);
    try {
      final project = await SupabaseService.createProject({
        'name': _nameCtrl.text.trim(),
        'address': _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim().isEmpty ? 'Hyderabad' : _cityCtrl.text.trim(),
        'total_budget_paise': _budgetCtrl.text.isEmpty ? 0 : (double.parse(_budgetCtrl.text) * 100).round(),
        'start_date': _startDate?.toIso8601String().substring(0, 10),
        'expected_end_date': _endDate?.toIso8601String().substring(0, 10),
      });
      ref.read(selectedProjectIdProvider.notifier).state = project.id;
      ref.invalidate(projectsProvider);
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

// lib/screens/dashboard/project_selection_screen.dart
class ProjectSelectionScreen extends ConsumerWidget {
  const ProjectSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    final selectedId = ref.watch(selectedProjectIdProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('My projects')),
      body: projectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (projects) {
          if (projects.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.construction_outlined, size: 64, color: Color(0xFFDDDDDD)),
                const SizedBox(height: 16),
                const Text('No projects yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('Create your first project to get started', style: TextStyle(color: Color(0xFF9E9E9E))),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.push('/create-project'),
                  child: const Text('Create project'),
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length + 1,
            itemBuilder: (_, i) {
              if (i == projects.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/create-project'),
                    icon: const Icon(Icons.add),
                    label: const Text('New project'),
                  ),
                );
              }
              final p = projects[i];
              final isSelected = p.id == selectedId;
              return GestureDetector(
                onTap: () {
                  ref.read(selectedProjectIdProvider.notifier).state = p.id;
                  context.go('/dashboard');
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF378ADD) : const Color(0xFFEEEEEE),
                      width: isSelected ? 2 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F1FB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.home_work_outlined, color: Color(0xFF378ADD)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            if (p.city != null)
                              Text(p.city!, style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                          ],
                        ),
                      ),
                      if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF378ADD)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
