import '../entities/surah.dart';
import '../entities/verse.dart';

abstract class QuranRepository {
  List<Surah> getAllSurahs();

  Surah? getSurahById(int surahId);

  Future<List<Verse>> getVersesBySurah(int surahId);

  Future<List<Verse>> getVersesByPage(int pageNumber);

  Future<Verse?> getVerseByReference({
    required int surahId,
    required int ayahNumber,
  });

  Future<List<Verse>> searchVerses(String query, {int limit = 20});
}
