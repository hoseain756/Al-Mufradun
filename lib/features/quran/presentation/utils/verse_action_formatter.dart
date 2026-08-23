import '../actions/verse_action_models.dart';
import 'arabic_number_formatter.dart';

class VerseActionFormatter {
  const VerseActionFormatter._();

  static String formatForCopy({
    required VerseActionContext context,
  }) {
    return _formatVersesWithReference(context);
  }

  static String formatForTextShare({
    required VerseActionContext context,
  }) {
    return _formatVersesWithReference(context);
  }

  static String formatSelectionSummary(VerseActionContext context) {
    final startAya = ArabicNumberFormatter.format(context.startVerse.ayahNumber);
    final endAya = ArabicNumberFormatter.format(context.endVerse.ayahNumber);

    if (!context.isRange) {
      return 'سورة ${context.startSurah.name} • الآية $startAya';
    }

    if (context.startSurah.id == context.endSurah.id) {
      return 'سورة ${context.startSurah.name} • من الآية $startAya إلى الآية $endAya';
    }

    return 'من سورة ${context.startSurah.name} • الآية $startAya إلى سورة ${context.endSurah.name} • الآية $endAya';
  }

  static String verseMarker(int ayahNumber) {
    return '﴿${ArabicNumberFormatter.format(ayahNumber)}﴾';
  }

  static String _formatVersesWithReference(VerseActionContext context) {
    final buffer = StringBuffer();
    for (var i = 0; i < context.verses.length; i++) {
      final verse = context.verses[i];
      if (i > 0) buffer.writeln();
      buffer.write('${verse.text} ${verseMarker(verse.ayahNumber)}');
    }
    buffer
      ..writeln()
      ..write(formatSelectionSummary(context));
    return buffer.toString();
  }
}
