class ScanDocument {
  final int? id;
  final String title;
  final List<String> pagePaths; // 本地图片路径列表
  final String? pdfPath;
  final DateTime createdAt;
  final int pageCount;

  ScanDocument({
    this.id,
    required this.title,
    required this.pagePaths,
    this.pdfPath,
    required this.createdAt,
    required this.pageCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'pagePaths': pagePaths.join('|||'),
      'pdfPath': pdfPath,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'pageCount': pageCount,
    };
  }

  factory ScanDocument.fromMap(Map<String, dynamic> map) {
    return ScanDocument(
      id: map['id'] as int?,
      title: map['title'] as String,
      pagePaths: (map['pagePaths'] as String).split('|||'),
      pdfPath: map['pdfPath'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      pageCount: map['pageCount'] as int,
    );
  }

  ScanDocument copyWith({
    int? id,
    String? title,
    List<String>? pagePaths,
    String? pdfPath,
    DateTime? createdAt,
    int? pageCount,
  }) {
    return ScanDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      pagePaths: pagePaths ?? this.pagePaths,
      pdfPath: pdfPath ?? this.pdfPath,
      createdAt: createdAt ?? this.createdAt,
      pageCount: pageCount ?? this.pageCount,
    );
  }
}
