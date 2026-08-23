import '../../domain/entities/surah.dart';
import '../../domain/entities/verse.dart';
import '../../domain/repositories/quran_repository.dart';
import '../local/quran_local_data_source.dart';
import '../static/mushaf_page_mapping.dart';
import '../static/surah_metadata.dart';

class QuranRepositoryImpl implements QuranRepository {
  const QuranRepositoryImpl({
    required QuranLocalDataSource localDataSource,
    List<Surah> surahs = kSurahMetadata,
  })  : _localDataSource = localDataSource,
        _surahs = surahs;

  final QuranLocalDataSource _localDataSource;
  final List<Surah> _surahs;

  @override
  List<Surah> getAllSurahs() => List.unmodifiable(_surahs);

  @override
  Surah? getSurahById(int surahId) {
    for (final surah in _surahs) {
      if (surah.id == surahId) {
        return surah;
      }
    }
    return null;
  }

  @override
  Future<List<Verse>> getVersesBySurah(int surahId) async {
    final surah = getSurahById(surahId);
    if (surah == null) {
      throw RangeError.range(surahId, 1, 114, 'surahId');
    }

    final verseModels = await _localDataSource.getVersesBySurah(surahId);
    return verseModels.map((verse) => verse.toEntity()).toList(growable: false);
  }

  @override
  Future<Verse?> getVerseByReference({
    required int surahId,
    required int ayahNumber,
  }) async {
    final surah = getSurahById(surahId);
    if (surah == null || ayahNumber < 1 || ayahNumber > surah.versesCount) {
      return null;
    }

    final verseModel = await _localDataSource.getVerseByReference(
      surahId: surahId,
      ayahNumber: ayahNumber,
    );
    return verseModel?.toEntity();
  }

  @override
  Future<List<Verse>> searchVerses(
    String query, {
    int limit = 20,
  }) async {
    final verseModels = await _localDataSource.searchVerses(
      query,
      limit: limit,
    );
    return verseModels.map((verse) => verse.toEntity()).toList(growable: false);
  }

  @override
  Future<List<Verse>> getVersesByPage(int pageNumber) async {
    final pageInfo = pageInfoForPage(pageNumber);
    final nextPageInfo = nextPageInfoForPage(pageNumber);
    final verseModels = await _localDataSource.getVersesByPageRange(
      startSura: pageInfo.startSura,
      startAya: pageInfo.startAya,
      nextStartSura: nextPageInfo?.startSura,
      nextStartAya: nextPageInfo?.startAya,
    );
    return verseModels.map((verse) => verse.toEntity()).toList(growable: false);
  }
}
