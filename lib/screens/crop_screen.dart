import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../services/image_processor.dart';

class CropScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const CropScreen({super.key, required this.imageBytes});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  late final img.Image? _decoded;
  double _left = 0.04;
  double _top = 0.04;
  double _right = 0.04;
  double _bottom = 0.04;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _decoded = img.decodeImage(widget.imageBytes);
  }

  Future<void> _saveCrop() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final image = _decoded;
      if (image == null) {
        if (mounted) Navigator.pop(context, widget.imageBytes);
        return;
      }

      final width = image.width;
      final height = image.height;
      final x = (_left * width).round();
      final y = (_top * height).round();
      final cropWidth = math.max(1, width - x - (_right * width).round());
      final cropHeight = math.max(1, height - y - (_bottom * height).round());

      final cropped = await ImageProcessor.cropImage(
        widget.imageBytes,
        x,
        y,
        cropWidth,
        cropHeight,
      );

      if (mounted) Navigator.pop(context, cropped);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _reset() {
    setState(() {
      _left = 0.04;
      _top = 0.04;
      _right = 0.04;
      _bottom = 0.04;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Manual Crop'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveCrop,
            child: Text(
              _isSaving ? 'Saving...' : 'Done',
              style: const TextStyle(color: Colors.lightBlue),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image.memory(
                    widget.imageBytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Container(
              color: Colors.grey.shade900,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MarginSlider(
                    label: 'Left',
                    value: _left,
                    onChanged: (v) => setState(() => _left = v),
                  ),
                  _MarginSlider(
                    label: 'Top',
                    value: _top,
                    onChanged: (v) => setState(() => _top = v),
                  ),
                  _MarginSlider(
                    label: 'Right',
                    value: _right,
                    onChanged: (v) => setState(() => _right = v),
                  ),
                  _MarginSlider(
                    label: 'Bottom',
                    value: _bottom,
                    onChanged: (v) => setState(() => _bottom = v),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _reset,
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isSaving ? null : _saveCrop,
                          child: const Text('Apply Crop'),
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
}

class _MarginSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _MarginSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 0.35,
            divisions: 35,
            label: '${(value * 100).round()}%',
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '${(value * 100).round()}%',
            textAlign: TextAlign.end,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}
