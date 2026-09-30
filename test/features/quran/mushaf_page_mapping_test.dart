import 'package:flutter_test/flutter_test.dart';

import 'package:adhkar_viewer/features/quran/data/static/mushaf_page_mapping.dart';

void main() {
  group('Mushaf page mapping', () {
    test('kMushafPageInfo covers all 604 pages in order', () {
      expect(kMushafPageCount, 604);
      expect(kMushafPageInfo.length, 604);
      for (var i = 0; i < kMushafPageInfo.length; i++) {
        expect(kMushafPageInfo[i].pageNumber, i + 1);
      }
    });

    test('pageInfoForPage validates bounds and returns entry', () {
      expect(pageInfoForPage(1).startSura, 1);
      expect(() => pageInfoForPage(0), throwsRangeError);
      expect(() => pageInfoForPage(605), throwsRangeError);
    });

    test('nextPageInfoForPage is null on the last page', () {
      expect(nextPageInfoForPage(604), isNull);
      expect(nextPageInfoForPage(603)?.pageNumber, 604);
    });

    test('pageNumberForVerse resolves known verse positions', () {
      // Al-Fatiha 1:1 is on page 1.
      expect(pageNumberForVerse(sura: 1, aya: 1), 1);
      // Al-Baqarah 2:1 starts page 2.
      expect(pageNumberForVerse(sura: 2, aya: 1), 2);
      // Verses must never resolve outside the 604-page Mushaf.
      for (final info in kMushafPageInfo) {
        final page = pageNumberForVerse(sura: info.startSura, aya: info.startAya);
        expect(page, inInclusiveRange(1, 604));
      }
    });

    test('pageNumberForVerse validates inputs', () {
      expect(() => pageNumberForVerse(sura: 0, aya: 1), throwsArgumentError);
      expect(() => pageNumberForVerse(sura: 1, aya: -1), throwsArgumentError);
    });

    test('quranPageFontFamily pads page numbers to 3 digits', () {
      expect(quranPageFontFamily(1), 'QCF2001');
      expect(quranPageFontFamily(42), 'QCF2042');
      expect(quranPageFontFamily(604), 'QCF2604');
    });
  });
}
