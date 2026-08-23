import '../entities/surah.dart';
import '../repositories/quran_repository.dart';

class GetAllSurahs {
  const GetAllSurahs(this.repository);

  final QuranRepository repository;

  List<Surah> call() => repository.getAllSurahs();
}
