// lib/screens/issues/issues_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';

class IssuesScreen extends ConsumerStatefulWidget {
  const IssuesScreen({super.key});
  @override
  ConsumerState<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends ConsumerState<IssuesScreen> {
  String _filter = 'open';

  @override
  Widget build(BuildContext context) {
    final projectId = ref.watch(selectedProjectIdProvider);
    if (projectId == null) return const LoadingScreen();

    final issuesAsync = ref.watch(issuesProvider(projectId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Issues & snags'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: FilterChips(
              options: const ['open', 'in_progress', 'resolved', 'closed'],
              labels: const ['Open', 'In progress', 'Resolved', 'Closed'],
              selected: _filter,
              onSelected: (v) => setState(() => _filter = v),
            ),
          ),
        ),
      ),
      body: issuesAsync.when(
        loading: () => const LoadingScreen(),
        error: (e, _) => Center(child: Text('$e')),
        data: (issues) {
          final filtered = issues.where((i) => i.status == _filter).toList();
          if (filtered.isEmpty) {
            return EmptyState(
              title: _filter == 'open' ? 'No open issues' : 'No $_filter issues',
              subtitle: _filter == 'open' ? 'Great! Everything is on track.' : 'Nothing here yet.',
              icon: Icons.bug_report_outlined,
              buttonLabel: _filter == 'open' ? 'Log issue' : null,
              onButton: () => _showAddIssue(context, ref, projectId),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _IssueCard(issue: filtered[i], ref: ref, projectId: projectId),
          );
        },
      ),
      floatingActionButton: NirmanFAB(
        onTap: () => _showAddIssue(context, ref, projectId),
        label: 'Log issue',
      ),
    );
  }

  void _showAddIssue(BuildContext context, WidgetRef ref, String projectId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _AddIssueSheet(projectId: projectId, ref: ref),
    );
  }
}

class _IssueCard extends StatelessWidget {
  final Issue issue;
  final WidgetRef ref;
  final String projectId;

  const _IssueCard({required this.issue, required this.ref, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: issue.status == 'open' ? const Color(0xFFF09595) : const Color(0xFFEEEEEE),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(issue.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              StatusBadge(issue.status),
            ],
          ),
          if (issue.description != null) ...[
            const SizedBox(height: 4),
            Text(issue.description!, style: const TextStyle(fontSize: 12, color: Color(0xFF666666)), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              PriorityBadge(issue.priority),
              const SizedBox(width: 12),
              if (issue.phaseName != null) ...[
                const Icon(Icons.layers_outlined, size: 11, color: Color(0xFF9E9E9E)),
                const SizedBox(width: 3),
                Text(issue.phaseName!, style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                const SizedBox(width: 12),
              ],
              if (issue.reportedByName != null) ...[
                const Icon(Icons.person_outline, size: 11, color: Color(0xFF9E9E9E)),
                const SizedBox(width: 3),
                Text(issue.reportedByName!, style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
              ],
            ],
          ),
          if (issue.status == 'open') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: OutlinedButton(
                      onPressed: () => _updateStatus('in_progress', ref, projectId),
                      style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text('Start fixing', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () => _updateStatus('resolved', ref, projectId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D9E75),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Mark resolved', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _updateStatus(String status, WidgetRef ref, String projectId) async {
    await SupabaseService.updateIssue(issue.id, {
      'status': status,
      if (status == 'resolved') 'resolved_at': DateTime.now().toIso8601String(),
    });
    ref.invalidate(issuesProvider(projectId));
  }
}

class _AddIssueSheet extends StatefulWidget {
  final String projectId;
  final WidgetRef ref;
  const _AddIssueSheet({required this.projectId, required this.ref});

  @override
  State<_AddIssueSheet> createState() => _AddIssueSheetState();
}

class _AddIssueSheetState extends State<_AddIssueSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'medium';
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
            const Text('Log issue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Issue title', hintText: 'e.g. Crack found in west wall')),
            const SizedBox(height: 12),
            TextField(controller: _descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description', hintText: 'More details...')),
            const SizedBox(height: 12),
            NirmanDropdown<String>(
              label: 'Priority',
              selected: _priority,
              items: const {'low': 'Low', 'medium': 'Medium', 'high': 'High', 'critical': 'Critical'},
              onChanged: (v) => setState(() => _priority = v),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Log issue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await SupabaseService.createIssue({
        'project_id': widget.projectId,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'priority': _priority,
        'status': 'open',
      });
      widget.ref.invalidate(issuesProvider(widget.projectId));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

