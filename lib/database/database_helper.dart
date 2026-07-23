import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/sentence.dart';
import '../models/word_collection.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'learn_en.db';
  static const _dbVersion = 1;

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE collections (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            created_at INTEGER NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE sentences (
            id TEXT PRIMARY KEY,
            text TEXT NOT NULL,
            collection_id TEXT,
            created_at INTEGER NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1,
            FOREIGN KEY (collection_id) REFERENCES collections (id) ON DELETE SET NULL
          )
        ''');
      },
    );
  }

  Future<List<WordCollection>> getCollections() async {
    final db = await database;
    final rows = await db.query(
      'collections',
      orderBy: 'created_at DESC',
    );
    return rows.map(WordCollection.fromMap).toList();
  }

  Future<WordCollection?> getCollection(String id) async {
    final db = await database;
    final rows = await db.query(
      'collections',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WordCollection.fromMap(rows.first);
  }

  Future<void> insertCollection(WordCollection collection) async {
    final db = await database;
    await db.insert('collections', collection.toMap());
  }

  Future<void> updateCollection(WordCollection collection) async {
    final db = await database;
    await db.update(
      'collections',
      collection.toMap(),
      where: 'id = ?',
      whereArgs: [collection.id],
    );
  }

  Future<void> deleteCollection(String id) async {
    final db = await database;
    await db.delete('collections', where: 'id = ?', whereArgs: [id]);
    await db.update(
      'sentences',
      {'collection_id': null},
      where: 'collection_id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Sentence>> getSentences({String? collectionId}) async {
    final db = await database;
    if (collectionId == null) {
      final rows = await db.query('sentences', orderBy: 'created_at DESC');
      return rows.map(Sentence.fromMap).toList();
    }

    final rows = await db.query(
      'sentences',
      where: 'collection_id = ?',
      whereArgs: [collectionId],
      orderBy: 'created_at DESC',
    );
    return rows.map(Sentence.fromMap).toList();
  }

  Future<List<Sentence>> getActiveSentencesForReminder({
    bool useAllCollections = true,
    List<String> collectionIds = const [],
  }) async {
    final db = await database;

    if (useAllCollections || collectionIds.isEmpty) {
      final rows = await db.query(
        'sentences',
        where: 'is_active = 1',
      );
      return rows.map(Sentence.fromMap).toList();
    }

    final placeholders = List.filled(collectionIds.length, '?').join(', ');
    final rows = await db.query(
      'sentences',
      where: 'is_active = 1 AND collection_id IN ($placeholders)',
      whereArgs: collectionIds,
    );
    return rows.map(Sentence.fromMap).toList();
  }

  Future<Sentence?> getSentence(String id) async {
    final db = await database;
    final rows = await db.query(
      'sentences',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Sentence.fromMap(rows.first);
  }

  Future<void> insertSentence(Sentence sentence) async {
    final db = await database;
    await db.insert('sentences', sentence.toMap());
  }

  Future<void> insertSentences(List<Sentence> sentences) async {
    final db = await database;
    final batch = db.batch();
    for (final sentence in sentences) {
      batch.insert('sentences', sentence.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateSentence(Sentence sentence) async {
    final db = await database;
    await db.update(
      'sentences',
      sentence.toMap(),
      where: 'id = ?',
      whereArgs: [sentence.id],
    );
  }

  Future<void> deleteSentence(String id) async {
    final db = await database;
    await db.delete('sentences', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countSentences({String? collectionId}) async {
    final db = await database;
    if (collectionId == null) {
      final result = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM sentences'),
      );
      return result ?? 0;
    }

    final result = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM sentences WHERE collection_id = ?',
        [collectionId],
      ),
    );
    return result ?? 0;
  }
}
