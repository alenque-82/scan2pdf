import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import '../providers/scan_provider.dart';
import '../services/image_processor.dart';
import '../services/pdf_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class EditScreen extends StatefulWidget {
  const EditScreen({super.key});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final TextEditingController _titleController = TextEditingController();
  int _selectedPageIndex = 0;
  ImageFilter _selectedFilter = ImageFilter.original;
  bool _isExporting = false;

  final List<_FilterOption> _filters = [
    _FilterOption(ImageFilter.original, 'Original', Icons.image),
    _FilterOption(ImageFilter.enhanced, 'Enhanced', Icons.auto_fix_high),
    _FilterOption(ImageFilter.blackAndWhite, 'B&W', Icons.contrast),
    _FilterOption(ImageFilter.grayscale, 'Gray', Icons.filter_b_and_w),
  ];

  @override
  void initState() {
    super.initState();
    final doc = context.read<ScanProvider>().currentDocument;
    _titleController.text = doc?.title ?? 'Scan ${DateTime.now().toString().substring(0, 16)}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _onFilterChanged(ImageFilter filter) async {
    setState(() => _selectedFilter = filter);
    await context.read<ScanProvider>().updatePageFilter(_selectedPageIndex, filter);
  }

  Future<void> _exportPdf() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final provider = context.read<ScanProvider>();
      final doc = await provider.finishScan(_titleController.text);

      if (doc != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved: ${doc.pdfPath}'),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }

    if (mounted) setState(() => _isExporting = false);
  }

  Future<void> _sharePdf() async {
    final doc = context.read<ScanProvider>().currentDocument;
    if (doc?.pdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No PDF to share. Export first.')),
      );
      return;
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(doc!.pdfPath!)],
        text: doc.title,
      ),
    );
  }

  Future<void> _shareImages() async {
    final pages = context.read<ScanProvider>().processedPages;
    if (pages.isEmpty) return;

    final files = pages.map((p) => XFile(p)).toList();
    await SharePlus.instance.share(
      ShareParams(
        files: files,
        text: 'Scanned pages',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScanProvider>();
    final pages = provider.processedPages;
    final currentDoc = provider.currentDocument;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareImages,
            tooltip: 'Share as Images',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _sharePdf,
            tooltip: 'Share PDF',
          ),
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_alt),
            onPressed: _isExporting ? null : _exportPdf,
            tooltip: 'Export PDF',
          ),
        ],
      ),
      body: Column(
        children: [
          // Page Thumbnail Strip
          if (pages.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedPageIndex;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedPageIndex = index;
                      final filters = provider.pageFilters;
                      if (index < filters.length) {
                        _selectedFilter = filters[index];
                      }
                    }),
                    onLongPress: () => _showDeleteDialog(index),
                    child: Container(
                      width: 56,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          File(pages[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          const Divider(height: 1),

          // Main Preview
          Expanded(
            child: pages.isEmpty
                ? const Center(child: Text('No pages scanned yet.'))
                : Padding(
                    padding: const EdgeInsets.all(8),
                    child: InteractiveViewer(
                      child: Image.file(
                        File(pages[_selectedPageIndex]),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
          ),

          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _filters.map((f) {
                final isSelected = f.filter == _selectedFilter;
                return GestureDetector(
                  onTap: () => _onFilterChanged(f.filter),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blueGrey.shade700 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          f.icon,
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        f.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected ? Colors.blueGrey.shade700 : Colors.grey,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Bottom Actions
          Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              children: [
                // Title input
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Document Title',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/camera'),
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Add Page'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isExporting ? null : _exportPdf,
                        icon: _isExporting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.picture_as_pdf),
                        label: Text(_isExporting ? 'Exporting...' : 'Export PDF'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Page'),
        content: Text('Delete page ${index + 1}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ScanProvider>().removePage(index);
              if (_selectedPageIndex >= context.read<ScanProvider>().processedPages.length) {
                setState(() => _selectedPageIndex = 0);
              }
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _FilterOption {
  final ImageFilter filter;
  final String label;
  final IconData icon;

  _FilterOption(this.filter, this.label, this.icon);
}
