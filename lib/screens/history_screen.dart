import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/scan_provider.dart';
import '../models/scan_document.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _showDeleteAllDialog(context),
            tooltip: 'Delete All',
          ),
        ],
      ),
      body: Consumer<ScanProvider>(
        builder: (context, provider, child) {
          final docs = provider.documents;

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No documents yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              return _DocCard(doc: doc);
            },
          );
        },
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Documents'),
        content: const Text('This will permanently delete all scanned documents. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final provider = context.read<ScanProvider>();
              for (final doc in provider.documents) {
                provider.deleteDocument(doc.id!);
              }
              Navigator.pop(context);
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  final ScanDocument doc;

  const _DocCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          context.read<ScanProvider>().openDocument(doc);
          Navigator.pushNamed(context, '/edit');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail strip
            SizedBox(
              height: 72,
              child: Row(
                children: doc.pagePaths.asMap().entries.map((entry) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.grey.shade200,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.file(
                        File(entry.value),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${doc.pageCount} page(s) · ${_formatDate(doc.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) => _handleAction(context, value, doc),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'share_pdf',
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf, size: 20),
                            SizedBox(width: 8),
                            Text('Share PDF'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share_imgs',
                        child: Row(
                          children: [
                            Icon(Icons.image, size: 20),
                            SizedBox(width: 8),
                            Text('Share Images'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Rename'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  void _handleAction(BuildContext context, String action, ScanDocument doc) {
    switch (action) {
      case 'share_pdf':
        if (doc.pdfPath != null) {
          Share.shareXFiles([XFile(doc.pdfPath!)], text: doc.title);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No PDF available')),
          );
        }
        break;
      case 'share_imgs':
        final files = doc.pagePaths.map((p) => XFile(p)).toList();
        Share.shareXFiles(files, text: doc.title);
        break;
      case 'rename':
        _showRenameDialog(context, doc);
        break;
      case 'delete':
        _showDeleteDialog(context, doc);
        break;
    }
  }

  void _showRenameDialog(BuildContext context, ScanDocument doc) {
    final controller = TextEditingController(text: doc.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Document Title',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                final updated = doc.copyWith(title: newTitle);
                // 更新逻辑通过 provider
                context.read<ScanProvider>().loadDocuments();
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ScanDocument doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Delete "${doc.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ScanProvider>().deleteDocument(doc.id!);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
