import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class QuranDatabaseHelper {
  QuranDatabaseHelper._();

  static const String assetPath = 'assets/db/quran.db';
  static const String databaseFileName = 'quran.db';
  static const String quranTextTable = 'quran_text';

  static Database? _database;

  static Future<Database> get database async {
    final existing = _database;
    if (existing != null && existing.isOpen) {
      return existing;
    }

    final dbPath = await _ensureDatabaseCopied();
    final db = await openDatabase(dbPath, readOnly: true);
    await validateSchema(db);
    _database = db;
    return db;
  }

  static Future<String> databasePath() async {
    final databasesPath = await getDatabasesPath();
    return p.join(databasesPath, databaseFileName);
  }

  static Future<void> validateSchema(Database db) async {
    final tableRows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      [quranTextTable],
    );
    if (tableRows.isEmpty) {
      throw const QuranDatabaseException(
        'Missing required table: quran_text.',
      );
    }

    final columns = await db.rawQuery('PRAGMA table_info($quranTextTable)');
    final columnsByName = {
      for (final column in columns) column['name'] as String: column,
    };

    const expectedColumns = <String, String>{
      'idx': 'INTEGER',
      'sura': 'INTEGER',
      'aya': 'INTEGER',
      'text': 'TEXT',
      'qcf_text': 'TEXT',
    };

    for (final entry in expectedColumns.entries) {
      final column = columnsByName[entry.key];
      if (column == null) {
        throw QuranDatabaseException(
          'Missing required column: ${entry.key}.',
        );
      }

      final type = (column['type'] as String? ?? '').toUpperCase();
      if (type != entry.value) {
        throw QuranDatabaseException(
          'Invalid column type for ${entry.key}: expected '
          '${entry.value}, found $type.',
        );
      }
    }

    final stats = (await db.rawQuery('''
      SELECT
        COUNT(*) AS total_verses,
        MIN(idx) AS min_idx,
        MAX(idx) AS max_idx,
        MIN(sura) AS min_sura,
        MAX(sura) AS max_sura
      FROM $quranTextTable
    ''')).single;

    _expectInt(stats, 'total_verses', 6236);
    _expectInt(stats, 'min_idx', 1);
    _expectInt(stats, 'max_idx', 6236);
    _expectInt(stats, 'min_sura', 1);
    _expectInt(stats, 'max_sura', 114);

    final duplicates = Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(*) FROM (
        SELECT sura, aya
        FROM $quranTextTable
        GROUP BY sura, aya
        HAVING COUNT(*) > 1
      )
    '''));
    if (duplicates != 0) {
      throw QuranDatabaseException(
        'Duplicate sura/aya rows found: $duplicates.',
      );
    }

    final missingQcfRows = Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(*)
      FROM $quranTextTable
      WHERE qcf_text IS NULL OR qcf_text = ''
    '''));
    if (missingQcfRows != 0) {
      throw QuranDatabaseException(
        'Missing QCF text rows found: $missingQcfRows.',
      );
    }
  }

  static Future<void> close() async {
    final existing = _database;
    _database = null;
    if (existing != null && existing.isOpen) {
      await existing.close();
    }
  }

  static Future<String> _ensureDatabaseCopied() async {
    final dbPath = await databasePath();
    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      try {
        final existingDb = await openDatabase(dbPath, readOnly: true);
        try {
          await validateSchema(existingDb);
          return dbPath;
        } finally {
          await existingDb.close();
        }
      } catch (_) {
        await dbFile.delete();
      }
    }

    await dbFile.parent.create(recursive: true);
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    await dbFile.writeAsBytes(bytes, flush: true);
    return dbPath;
  }

  static void _expectInt(
    Map<String, Object?> row,
    String key,
    int expected,
  ) {
    final actual = row[key];
    if (actual != expected) {
      throw QuranDatabaseException(
        'Invalid $key: expected $expected, found $actual.',
      );
    }
  }
}

class QuranDatabaseException implements Exception {
  const QuranDatabaseException(this.message);

  final String message;

  @override
  String toString() => 'QuranDatabaseException: $message';
}
