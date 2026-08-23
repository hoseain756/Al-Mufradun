import '../domain/repositories/quran_repository.dart';
import 'local/quran_local_data_source.dart';
import 'repositories/quran_repository_impl.dart';

QuranRepository createQuranRepository() {
  return QuranRepositoryImpl(
    localDataSource: SqliteQuranLocalDataSource(),
  );
}
