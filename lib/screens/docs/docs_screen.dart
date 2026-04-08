// lib/screens/docs/docs_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';

class DocsScreen extends ConsumerStatefulWidget {
  const DocsScreen({super.key});
  @override
  ConsumerState<DocsScreen> createState() => _DocsScreenState();
}

class _DocsScreenState extends ConsumerState<DocsScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final projectId = ref.watch(selectedProjectIdProvider);
    if (projectId == null) return const LoadingScreen();

    final docsAsync = ref.watch(documentsProvider(projectId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Docs & photos'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: FilterChips(
              options: const ['all', 'start_proof', 'completion_proof', 'drawing', 'invoice', 'contract'],
              labels: const ['All', 'Start', 'Completion', 'Drawings', 'Invoices', 'Contracts'],
              selected: _filter,
              onSelected: (v) => setState(() => _filter = v),
            ),
          ),
        ),
      ),
      body: docsAsync.when(
        loading: () => const LoadingScreen(),
        error: (e, _) => Center(child: Text('$e')),
        data: (docs) {
          final filtered = _filter == 'all' ? docs : docs.where((d) => d.docType == _filter).toList();
          final photos = filtered.where((d) => d.isImage).toList();
          final others = filtered.where((d) => !d.isImage).toList();

          if (filtered.isEmpty) {
            return EmptyState(
              title: 'No documents yet',
              subtitle: 'Upload photos and documents as proof of work',
              icon: Icons.folder_outlined,
              buttonLabel: 'Upload',
              onButton: () => _showUploadSheet(context, projectId),
            );
          }

          return CustomScrollView(
            slivers: [
              if (photos.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: SectionHeader('Photos (${photos.length})'),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _PhotoCard(doc: photos[i]),
                      childCount: photos.length,
                    ),
                  ),
                ),
              ],
              if (others.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: SectionHeader('Documents (${others.length})'),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: _DocCard(doc: others[i]),
                    ),
                    childCount: others.length,
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
      floatingActionButton: NirmanFAB(
        onTap: () => _showUploadSheet(context, projectId),
        label: 'Upload',
      ),
    );
  }

  void _showUploadSheet(BuildContext context, String projectId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _UploadSheet(projectId: projectId, ref: ref),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final AppDocument doc;
  const _PhotoCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: Image.network(
                doc.fileUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFF5F5F5),
                  child: const Icon(Icons.image_outlined, color: Color(0xFFDDDDDD), size: 36),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    _DocTypeBadge(doc.docType),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  final AppDocument doc;
  const _DocCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F1FB),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFB5D4F4)),
            ),
            child: Center(
              child: Text(
                doc.isPdf ? 'PDF' : doc.fileName?.split('.').last.toUpperCase() ?? 'FILE',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF185FA5)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${doc.createdAt.day}/${doc.createdAt.month}/${doc.createdAt.year}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
                    ),
                    if (doc.fileSizeBytes != null) ...[
                      const Text(' · ', style: TextStyle(color: Color(0xFF9E9E9E))),
                      Text(doc.fileSizeDisplay, style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                    ],
                  ],
                ),
              ],
            ),
          ),
          _DocTypeBadge(doc.docType),
        ],
      ),
    );
  }
}

class _DocTypeBadge extends StatelessWidget {
  final String type;
  const _DocTypeBadge(this.type);

  static const _labels = {
    'start_proof': 'Start',
    'completion_proof': 'Done',
    'drawing': 'Drawing',
    'invoice': 'Invoice',
    'contract': 'Contract',
    'approval': 'Approval',
    'misc': 'Misc',
  };

  static const _colors = {
    'start_proof': [0xFFFAEEDA, 0xFF854F0B],
    'completion_proof': [0xFFEAF3DE, 0xFF3B6D11],
    'drawing': [0xFFEEEDFE, 0xFF3C3489],
    'invoice': [0xFFE6F1FB, 0xFF185FA5],
    'contract': [0xFFF1EFE8, 0xFF5F5E5A],
    'approval': [0xFFEAF3DE, 0xFF3B6D11],
    'misc': [0xFFF1EFE8, 0xFF5F5E5A],
  };

  @override
  Widget build(BuildContext context) {
    final colors = _colors[type] ?? [0xFFF1EFE8, 0xFF5F5E5A];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Color(colors[0]),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _labels[type] ?? type,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(colors[1])),
      ),
    );
  }
}

class _UploadSheet extends StatefulWidget {
  final String projectId;
  final WidgetRef ref;
  const _UploadSheet({required this.projectId, required this.ref});

  @override
  State<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<_UploadSheet> {
  File? _file;
  final _titleCtrl = TextEditingController();
  String _docType = 'misc';
  bool _loading = false;
  final _picker = ImagePicker();

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
            const Text('Upload file', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            // File picker
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDDDDDD), style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    Icon(
                      _file != null ? Icons.check_circle : Icons.upload_file,
                      color: _file != null ? const Color(0xFF1D9E75) : const Color(0xFF9E9E9E),
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _file != null ? _file!.path.split('/').last : 'Tap to pick photo or document',
                      style: TextStyle(
                        fontSize: 13,
                        color: _file != null ? const Color(0xFF1D9E75) : const Color(0xFF9E9E9E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickFromCamera(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 18, color: Color(0xFF378ADD)),
                          SizedBox(width: 6),
                          Text('Camera', style: TextStyle(fontSize: 13, color: Color(0xFF378ADD))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickFile,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library_outlined, size: 18, color: Color(0xFF378ADD)),
                          SizedBox(width: 6),
                          Text('Gallery', style: TextStyle(fontSize: 13, color: Color(0xFF378ADD))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Foundation completion photo'),
            ),
            const SizedBox(height: 12),
            NirmanDropdown<String>(
              label: 'Type',
              selected: _docType,
              items: const {
                'start_proof': 'Start proof',
                'completion_proof': 'Completion proof',
                'drawing': 'Drawing',
                'invoice': 'Invoice / Bill',
                'contract': 'Contract',
                'approval': 'Approval',
                'misc': 'Miscellaneous',
              },
              onChanged: (v) => setState(() => _docType = v),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading || _file == null ? null : _upload,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Upload'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _file = File(picked.path));
  }

  Future<void> _pickFromCamera() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) setState(() => _file = File(picked.path));
  }

  Future<void> _upload() async {
    if (_file == null || _titleCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await SupabaseService.uploadDocument(
        projectId: widget.projectId,
        file: _file!,
        title: _titleCtrl.text.trim(),
        docType: _docType,
      );
      widget.ref.invalidate(documentsProvider(widget.projectId));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

