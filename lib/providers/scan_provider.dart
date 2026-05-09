import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/scan_document.dart';
import '../services/database_service.dart';
import '../services/image_processor.dart';
import '../services/pdf_service.dart';

class ScanProvider extends ChangeNotifier {
  List<ScanDocument> _documents = [];
  List<ScanDocument> get documents => _documents;

  ScanDocument? _currentDocument;
  ScanDocument? get currentDocument => _currentDocument;

  List<String> _currentPages = []; // 当前扫描的页面路径（原始图）
  List<String> get currentPages => _currentPages;

  List<String> _processedPages = []; // 当前扫描的页面路径（处理后）
  List<String> get processedPages => _processedPages;

  List<ImageFilter> _pageFilters = [];
  List<ImageFilter> get pageFilters => _pageFilters;

  ImageFilter _currentFilter = ImageFilter.original;
  ImageFilter get currentFilter => _currentFilter;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadDocuments() async {
    _isLoading = true;
    notifyListeners();

    try {
      _documents = await DatabaseService.instance.getAllDocuments();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 添加一页（拍照后）
  Future<void> addPage(Uint8List imageBytes) async {
    // 为这一批次生成临时ID
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final pageIndex = _currentPages.length;

    // 保存原始图
    final appDir = await getTemporaryDirectory();
    final batchDir = Directory('${appDir.path}/current_batch');
    if (!await batchDir.exists()) await batchDir.create(recursive: true);

    final rawPath = p.join(batchDir.path, 'raw_$pageIndex.jpg');
    await File(rawPath).writeAsBytes(imageBytes);
    _currentPages.add(rawPath);

    // 保存处理后图（原图+当前滤镜）
    final processedBytes = await ImageProcessor.applyFilter(imageBytes, _currentFilter);
    final processedPath = p.join(batchDir.path, 'processed_$pageIndex.jpg');
    await File(processedPath).writeAsBytes(processedBytes);
    _processedPages.add(processedPath);
    _pageFilters.add(_currentFilter);

    notifyListeners();
  }

  /// 更新某一页的滤镜
  Future<void> updatePageFilter(int pageIndex, ImageFilter filter) async {
    if (pageIndex < 0 || pageIndex >= _currentPages.length) return;

    _currentFilter = filter;
    final rawBytes = await File(_currentPages[pageIndex]).readAsBytes();
    final processedBytes = await ImageProcessor.applyFilter(rawBytes, filter);
    final processedPath = _processedPages[pageIndex];
    await File(processedPath).writeAsBytes(processedBytes);
    _pageFilters[pageIndex] = filter;
    notifyListeners();
  }

  /// 删除某一页
  Future<void> removePage(int pageIndex) async {
    if (pageIndex < 0 || pageIndex >= _currentPages.length) return;

    _currentPages.removeAt(pageIndex);
    _processedPages.removeAt(pageIndex);
    _pageFilters.removeAt(pageIndex);
    notifyListeners();
  }

  /// 重新拍摄某一页
  Future<void> replacePage(int pageIndex, Uint8List newImageBytes) async {
    if (pageIndex < 0 || pageIndex >= _currentPages.length) return;

    // 覆盖原始图
    await File(_currentPages[pageIndex]).writeAsBytes(newImageBytes);

    // 重新处理
    final processedBytes = await ImageProcessor.applyFilter(newImageBytes, _currentFilter);
    await File(_processedPages[pageIndex]).writeAsBytes(processedBytes);

    notifyListeners();
  }

  /// 完成扫描，保存文档
  Future<ScanDocument?> finishScan(String title) async {
    if (_processedPages.isEmpty) return null;

    _isLoading = true;
    notifyListeners();

    try {
      // 生成PDF
      final pdfPath = await PdfService.createPdfFromImages(
        _processedPages,
        title,
      );

      // 保存到数据库
      final doc = ScanDocument(
        title: title.isEmpty ? 'Scan ${DateTime.now().toString().substring(0, 16)}' : title,
        pagePaths: List.from(_processedPages),
        pdfPath: pdfPath,
        createdAt: DateTime.now(),
        pageCount: _processedPages.length,
      );

      final id = await DatabaseService.instance.insertDocument(doc);
      final savedDoc = doc.copyWith(id: id);

      _documents.insert(0, savedDoc);

      // 清空当前批次
      await _clearCurrentBatch();
      _currentDocument = null;

      _isLoading = false;
      notifyListeners();
      return savedDoc;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// 取消当前扫描
  Future<void> cancelScan() async {
    await _clearCurrentBatch();
    _currentDocument = null;
    notifyListeners();
  }

  /// 删除文档
  Future<void> deleteDocument(int id) async {
    ScanDocument? doc;
    try {
      doc = _documents.firstWhere((d) => d.id == id);
    } catch (_) {
      doc = null;
    }

    if (doc != null) {
      // 删除文件
      for (final path in doc.pagePaths) {
        try {
          await File(path).delete();
        } catch (_) {}
      }
      if (doc.pdfPath != null) {
        try {
          await File(doc.pdfPath!).delete();
        } catch (_) {}
      }
    }

    await DatabaseService.instance.deleteDocument(id);
    _documents.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  /// 打开历史文档进行编辑
  Future<void> openDocument(ScanDocument doc) async {
    _currentDocument = doc;
    _currentPages = List.from(doc.pagePaths);
    _processedPages = List.from(doc.pagePaths);
    _pageFilters = List.generate(doc.pagePaths.length, (_) => ImageFilter.original);
    notifyListeners();
  }

  Future<void> _clearCurrentBatch() async {
    _currentPages = [];
    _processedPages = [];
    _pageFilters = [];
    _currentFilter = ImageFilter.original;
  }
}
