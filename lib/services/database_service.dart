import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/scan_document.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  Database? _db;

  DatabaseService._();

  Future<Database> get db async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'doc_scanner.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE documents(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            pagePaths TEXT NOT NULL,
            pdfPath TEXT,
            createdAt INTEGER NOT NULL,
            pageCount INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertDocument(ScanDocument doc) async {
    final d = await db;
    return d.insert('documents', doc.toMap());
  }

  Future<List<ScanDocument>> getAllDocuments() async {
    final d = await db;
    final maps = await d.query(
      'documents',
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => ScanDocument.fromMap(m)).toList();
  }

  Future<ScanDocument?> getDocument(int id) async {
    final d = await db;
    final maps = await d.query(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ScanDocument.fromMap(maps.first);
  }

  Future<int> deleteDocument(int id) async {
    final d = await db;
    return d.delete('documents', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateDocument(ScanDocument doc) async {
    final d = await db;
    return d.update(
      'documents',
      doc.toMap(),
      where: 'id = ?',
      whereArgs: [doc.id],
    );
  }
}
