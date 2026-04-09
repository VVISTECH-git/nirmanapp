import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DocsScreen extends StatefulWidget {
  final String projectId;
  const DocsScreen({super.key, required this.projectId});

  @override
  State<DocsScreen> createState() => _DocsScreenState();
}

class _DocsScreenState extends State<DocsScreen> {
  final _client = Supabase.instance.client;
  final _picker = ImagePicker();
  List<Map<String, dynamic>> _docs = [];
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    try {
      final res = await _client
          .from('documents')
          .select()
          .eq('project_id', widget.projectId)
          .order('created_at', ascending: false);
      if (mounted) setState(() { _docs = List<Map<String, dynamic>>.from(res); _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    Navigator.pop(context);
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;

      setState(() => _uploading = true);

      final file = File(picked.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      final path = '${widget.projectId}/$fileName';

      // Upload to Supabase Storage
      await _client.storage.from('documents').upload(path, file);
      final fileUrl = _client.storage.from('documents').getPublicUrl(path);
      final stat = await file.stat();

      // Save to documents table
      await _client.from('documents').insert({
        'project_id': widget.projectId,
        'title': picked.name,
        'doc_type': 'misc',
        'file_url': fileUrl,
        'file_name': fileName,
        'file_size_bytes': stat.size,
        'mime_type': 'image/jpeg',
        'uploaded_by': _client.auth.currentUser!.id,
      });

      await _loadDocs();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo uploaded successfully!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showUploadSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Upload', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Take Photo'),
            onTap: () => _pickAndUpload(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from Gallery'),
            onTap: () => _pickAndUpload(ImageSource.gallery),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: Stack(children: [
        _docs.isEmpty
            ? Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.folder_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No documents yet', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Tap + to upload photos',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                ]),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _DocCard(doc: _docs[i]),
              ),
        if (_uploading)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadSheet,
        icon: const Icon(Icons.add),
        label: const Text('Upload'),
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  final Map<String, dynamic> doc;
  const _DocCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final type = doc['doc_type'] ?? 'other';
    final isPhoto = type == 'photo' || (doc['mime_type'] ?? '').startsWith('image/');
    final fileUrl = doc['file_url'] ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        // Thumbnail or icon
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: isPhoto && fileUrl.isNotEmpty
              ? Image.network(fileUrl, width: 48, height: 48, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _DocIcon(isPhoto: isPhoto))
              : _DocIcon(isPhoto: isPhoto),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(doc['title'] ?? doc['file_name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(doc['created_at']?.toString().substring(0, 10) ?? '',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(type, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ),
      ]),
    );
  }
}

class _DocIcon extends StatelessWidget {
  final bool isPhoto;
  const _DocIcon({required this.isPhoto});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: isPhoto ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        isPhoto ? Icons.image_outlined : Icons.description_outlined,
        color: isPhoto ? Colors.blue : Colors.orange,
      ),
    );
  }
}
