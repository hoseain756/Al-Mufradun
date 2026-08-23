import '../entities/verse.dart';
import '../repositories/quran_repository.dart';

class GetVersesBySurah {
  const GetVersesBySurah(this.repository);

  final QuranRepository repository;

  Future<List<Verse>> call(int surahId) {
    return repository.getVersesBySurah(surahId);
  }
}
