import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class PdfService {
  /// 将多张图片合并为一个PDF
  static Future<String> createPdfFromImages(
    List<String> imagePaths,
    String documentTitle,
  ) async {
    final pdf = pw.Document();

    for (final imagePath in imagePaths) {
      final file = File(imagePath);
      if (!await file.exists()) continue;

      final imageBytes = await file.readAsBytes();
      final image = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(0),
          build: (context) {
            return pw.Center(
              child: pw.Image(
                image,
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );
    }

    // 保存到应用文档目录
    final outputDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedTitle = documentTitle.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final fileName = '${sanitizedTitle}_$timestamp.pdf';
    final outputPath = p.join(outputDir.path, 'scans', fileName);

    final outDir = Directory(p.dirname(outputPath));
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }

    final file = File(outputPath);
    final bytes = await pdf.save();
    await file.writeAsBytes(bytes);

    return outputPath;
  }

  /// 导出PDF到Downloads目录（Android）
  static Future<String?> exportToDownloads(String pdfPath) async {
    try {
      // Android 10+ 用 SAF，不需要手动复制
      return pdfPath;
    } catch (e) {
      return null;
    }
  }

  /// 获取PDF文件大小（人类可读）
  static Future<String> getPdfSize(String pdfPath) async {
    final file = File(pdfPath);
    if (!await file.exists()) return '0 B';

    final bytes = await file.length();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
