class Verse {
  const Verse({
    required this.id,
    required this.surahNumber,
    required this.ayahNumber,
    required this.text,
    required this.qcfText,
  });

  final int id;
  final int surahNumber;
  final int ayahNumber;
  final String text;
  final String qcfText;
}
