import 'package:sqflite/sqflite.dart';

import '../models/verse_model.dart';
import 'quran_database_helper.dart';

abstract class QuranLocalDataSource {
  Future<List<VerseModel>> getVersesBySurah(int surahId);

  Future<VerseModel?> getVerseByReference({
    required int surahId,
    required int ayahNumber,
  });

  Future<List<VerseModel>> searchVerses(String query, {int limit = 20});

  Future<List<VerseModel>> getVersesByPageRange({
    required int startSura,
    required int startAya,
    required int? nextStartSura,
    required int? nextStartAya,
  });
}

class SqliteQuranLocalDataSource implements QuranLocalDataSource {
  SqliteQuranLocalDataSource({
    Future<Database> Function()? databaseProvider,
  }) : _databaseProvider =
            databaseProvider ?? (() => QuranDatabaseHelper.database);

  final Future<Database> Function() _databaseProvider;

  @override
  Future<List<VerseModel>> getVersesBySurah(int surahId) async {
    final db = await _databaseProvider();
    final rows = await db.query(
      QuranDatabaseHelper.quranTextTable,
      where: 'sura = ?',
      whereArgs: [surahId],
      orderBy: 'aya ASC',
    );
    return rows.map(VerseModel.fromDatabaseMap).toList(growable: false);
  }

  @override
  Future<VerseModel?> getVerseByReference({
    required int surahId,
    required int ayahNumber,
  }) async {
    final db = await _databaseProvider();
    final rows = await db.query(
      QuranDatabaseHelper.quranTextTable,
      where: 'sura = ? AND aya = ?',
      whereArgs: [surahId, ayahNumber],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return VerseModel.fromDatabaseMap(rows.first);
  }

  @override
  Future<List<VerseModel>> searchVerses(
    String query, {
    int limit = 20,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return const [];

    final db = await _databaseProvider();
    final rows = await db.query(
      QuranDatabaseHelper.quranTextTable,
      where: 'text LIKE ?',
      whereArgs: ['%$normalizedQuery%'],
      orderBy: 'idx ASC',
      limit: limit,
    );
    return rows.map(VerseModel.fromDatabaseMap).toList(growable: false);
  }

  @override
  Future<List<VerseModel>> getVersesByPageRange({
    required int startSura,
    required int startAya,
    required int? nextStartSura,
    required int? nextStartAya,
  }) async {
    final db = await _databaseProvider();
    final hasEnd = nextStartSura != null && nextStartAya != null;
    final rows = await db.query(
      QuranDatabaseHelper.quranTextTable,
      where: hasEnd
          ? '''
((sura > ?) OR (sura = ? AND aya >= ?))
AND ((sura < ?) OR (sura = ? AND aya < ?))
'''
          : '((sura > ?) OR (sura = ? AND aya >= ?))',
      whereArgs: hasEnd
          ? [
              startSura,
              startSura,
              startAya,
              nextStartSura,
              nextStartSura,
              nextStartAya,
            ]
          : [startSura, startSura, startAya],
      orderBy: 'idx ASC',
    );
    return rows.map(VerseModel.fromDatabaseMap).toList(growable: false);
  }
}
