import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

enum ImageFilter {
  original,
  enhanced,
  blackAndWhite,
  grayscale,
}

class ImageProcessor {
  /// 对图片应用滤镜
  static Future<Uint8List> applyFilter(Uint8List imageBytes, ImageFilter filter) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    img.Image processed;

    switch (filter) {
      case ImageFilter.original:
        processed = image;
        break;
      case ImageFilter.enhanced:
        // 增强：提高对比度和亮度
        processed = img.adjustColor(
          image,
          contrast: 1.3,
          brightness: 1.05,
        );
        break;
      case ImageFilter.blackAndWhite:
        // 黑白：灰度 + 二值化
        processed = img.grayscale(image);
        processed = _threshold(processed, 128);
        break;
      case ImageFilter.grayscale:
        processed = img.grayscale(image);
        break;
    }

    return Uint8List.fromList(img.encodeJpg(processed, quality: 92));
  }

  /// 简单阈值二值化
  static img.Image _threshold(img.Image image, int value) {
    for (final pixel in image) {
      final luminance = ((pixel.r * 299) + (pixel.g * 587) + (pixel.b * 114)) ~/ 1000;
      if (luminance > value) {
        pixel
          ..r = 255
          ..g = 255
          ..b = 255;
      } else {
        pixel
          ..r = 0
          ..g = 0
          ..b = 0;
      }
    }
    return image;
  }

  /// 裁剪图片（手动裁边）
  static Future<Uint8List> cropImage(
    Uint8List imageBytes,
    int x,
    int y,
    int width,
    int height,
  ) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    final cropped = img.copyCrop(image, x: x, y: y, width: width, height: height);
    return Uint8List.fromList(img.encodeJpg(cropped, quality: 92));
  }

  /// 透视矫正（简化版：旋转校正）
  static Future<Uint8List> rotateIfNeeded(Uint8List imageBytes) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    // 检测是否需要旋转（这里简化处理，可接入ML Kit边缘检测后更精确）
    // 目前返回原图，旋转逻辑在UI层处理
    return imageBytes;
  }

  /// 保存处理后的图片到本地
  static Future<String> saveProcessedImage(
    Uint8List bytes,
    String documentId,
    int pageIndex,
  ) async {
    final dir = await _getDocDir(documentId);
    final file = File('${dir.path}/page_${pageIndex.toString().padLeft(3, '0')}.jpg');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  static Future<Directory> _getDocDir(String docId) async {
    final appDir = Directory.systemTemp;
    final docDir = Directory('${appDir.path}/scans/$docId');
    if (!await docDir.exists()) {
      await docDir.create(recursive: true);
    }
    return docDir;
  }

  /// 生成缩略图
  static Future<Uint8List> generateThumbnail(Uint8List imageBytes, {int maxSize = 300}) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    final thumbnail = img.copyResize(
      image,
      width: image.width > image.height ? maxSize : null,
      height: image.height >= image.width ? maxSize : null,
    );
    return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 70));
  }
}
