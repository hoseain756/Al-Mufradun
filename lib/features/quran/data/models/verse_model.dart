import '../../domain/entities/verse.dart';

class VerseModel {
  const VerseModel({
    required this.idx,
    required this.sura,
    required this.aya,
    required this.text,
    required this.qcfText,
  });

  final int idx;
  final int sura;
  final int aya;
  final String text;
  final String qcfText;

  factory VerseModel.fromDatabaseMap(Map<String, Object?> map) {
    return VerseModel(
      idx: _readInt(map, 'idx'),
      sura: _readInt(map, 'sura'),
      aya: _readInt(map, 'aya'),
      text: _readString(map, 'text'),
      qcfText: _readString(map, 'qcf_text'),
    );
  }

  Verse toEntity() {
    return Verse(
      id: idx,
      surahNumber: sura,
      ayahNumber: aya,
      text: text,
      qcfText: qcfText,
    );
  }

  static int _readInt(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is int) {
      return value;
    }
    throw FormatException('Expected integer column "$key", found $value.');
  }

  static String _readString(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    throw FormatException(
        'Expected non-empty text column "$key", found $value.');
  }
}
