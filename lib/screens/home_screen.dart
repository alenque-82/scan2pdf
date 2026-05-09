import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scan_provider.dart';
import 'camera_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScanProvider>().loadDocuments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doc Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/history'),
            tooltip: 'History',
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Scan Cards
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // New Scan Card
                  _ScanCard(
                    icon: Icons.document_scanner_outlined,
                    title: 'New Scan',
                    subtitle: 'Take photos or import images',
                    color: Colors.blueGrey.shade700,
                    onTap: () async {
                      final provider = context.read<ScanProvider>();
                      await provider.cancelScan();
                      if (mounted) Navigator.pushNamed(context, '/camera');
                    },
                  ),
                  const SizedBox(height: 12),
                  // Import Card
                  _ScanCard(
                    icon: Icons.add_photo_alternate_outlined,
                    title: 'Import',
                    subtitle: 'Import existing photos',
                    color: Colors.blueGrey.shade400,
                    onTap: () => _importImages(context),
                  ),
                  const SizedBox(height: 20),
                  // Recent Documents
                  if (context.watch<ScanProvider>().documents.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/history'),
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _RecentDocsList(
                        docs: context.watch<ScanProvider>().documents.take(3).toList(),
                      ),
                    ),
                  ] else
                    const Expanded(
                      child: Center(
                        child: Text(
                          'No documents yet.\nTap "New Scan" to start.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importImages(BuildContext context) async {
    // 简化：直接跳转相机（实际可用 file_picker）
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import feature: use file_picker or camera')),
    );
  }
}

class _ScanCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ScanCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentDocsList extends StatelessWidget {
  final List docs;

  const _RecentDocsList({required this.docs});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.blueGrey.shade100,
              ),
              child: const Icon(Icons.description, color: Colors.blueGrey),
            ),
            title: Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${doc.pageCount} page(s)'),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'share', child: Text('Share')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  context.read<ScanProvider>().deleteDocument(doc.id!);
                }
              },
            ),
            onTap: () {
              context.read<ScanProvider>().openDocument(doc);
              Navigator.pushNamed(context, '/edit');
            },
          ),
        );
      },
    );
  }
}
