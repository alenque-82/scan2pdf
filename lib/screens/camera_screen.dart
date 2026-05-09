import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../providers/scan_provider.dart';
import 'crop_screen.dart';
import '../services/image_processor.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isTaking = false;
  int _currentCameraIndex = 0;
  FlashMode _flashMode = FlashMode.auto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No camera found')),
          );
        }
        return;
      }
      await _setupCamera(_cameras![_currentCameraIndex]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  Future<void> _setupCamera(CameraDescription camera) async {
    _controller?.dispose();

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      await _controller!.setFlashMode(_flashMode);
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize camera: $e')),
        );
      }
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
    setState(() => _isInitialized = false);
    await _setupCamera(_cameras![_currentCameraIndex]);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    final modes = [FlashMode.auto, FlashMode.off, FlashMode.torch];
    final currentIdx = modes.indexOf(_flashMode);
    final nextIdx = (currentIdx + 1) % modes.length;
    _flashMode = modes[nextIdx];
    await _controller!.setFlashMode(_flashMode);
    setState(() {});
  }

  IconData get _flashIcon {
    switch (_flashMode) {
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.torch:
        return Icons.flash_on;
      default:
        return Icons.flash_auto;
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isTaking) return;
    setState(() => _isTaking = true);

    try {
      final XFile file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();

      if (mounted) {
        // 跳到手动裁边页面
        final result = await Navigator.push<Uint8List>(
          context,
          MaterialPageRoute(
            builder: (context) => CropScreen(imageBytes: bytes),
          ),
        );

        if (result != null && mounted) {
          await context.read<ScanProvider>().addPage(result);
          _showAddedSnackBar();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take picture: $e')),
        );
      }
    }

    if (mounted) setState(() => _isTaking = false);
  }

  void _showAddedSnackBar() {
    final pages = context.read<ScanProvider>().currentPages.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Page $pages added'),
        duration: const Duration(seconds: 1),
        action: SnackBarAction(
          label: 'Done',
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScanProvider>();
    final pageCount = provider.currentPages.length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(pageCount > 0 ? '$pageCount page(s) scanned' : 'New Scan'),
        actions: [
          if (pageCount > 0)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done', style: TextStyle(color: Colors.lightBlue)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Camera Preview
          Expanded(
            child: _isInitialized && _controller != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CameraPreview(_controller!),
                  )
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
          ),
          // Controls
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Flash
                IconButton(
                  icon: Icon(_flashIcon, color: Colors.white, size: 28),
                  onPressed: _toggleFlash,
                ),
                // Gallery (import)
                IconButton(
                  icon: const Icon(Icons.photo_library, color: Colors.white, size: 28),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Import from gallery - to be implemented')),
                    );
                  },
                ),
                // Shutter
                GestureDetector(
                  onTap: _isTaking ? null : _takePicture,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: _isTaking
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : Container(
                            margin: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                // Flip camera
                IconButton(
                  icon: const Icon(Icons.flip_camera_android, color: Colors.white, size: 28),
                  onPressed: _toggleCamera,
                ),
                // Page count indicator
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white54, width: 1),
                  ),
                  child: Text(
                    '$pageCount',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 拍照后确认 + 手动裁边页面（简化版 v1）
class _CropConfirmScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const _CropConfirmScreen({required this.imageBytes});

  @override
  State<_CropConfirmScreen> createState() => _CropConfirmScreenState();
}

class _CropConfirmScreenState extends State<_CropConfirmScreen> {
  late Uint8List _displayBytes;

  @override
  void initState() {
    super.initState();
    _displayBytes = widget.imageBytes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Confirm'),
        actions: [
          TextButton(
            onPressed: () async {
              // 应用原始图片（后续可加入裁剪逻辑）
              Navigator.pop(context, widget.imageBytes);
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.lightBlue)),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.memory(
            _displayBytes,
            fit: BoxFit.contain,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _BottomBtn(
              icon: Icons.crop,
              label: 'Crop',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Auto-crop: v2 feature')),
                );
              },
            ),
            _BottomBtn(
              icon: Icons.rotate_right,
              label: 'Rotate',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rotation: v2 feature')),
                );
              },
            ),
            _BottomBtn(
              icon: Icons.close,
              label: 'Discard',
              onTap: () => Navigator.pop(context),
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _BottomBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isDestructive ? Colors.red : Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isDestructive ? Colors.red : Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
