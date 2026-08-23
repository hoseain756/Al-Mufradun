import 'package:shared_preferences/shared_preferences.dart';

import '../../data/static/mushaf_page_mapping.dart';
import '../../domain/entities/verse.dart';

class QuranBookmark {
  const QuranBookmark({
    required this.surahNumber,
    required this.ayahNumber,
    required this.pageNumber,
  });

  final int surahNumber;
  final int ayahNumber;
  final int pageNumber;

  String get id => QuranBookmarkStore.keyFor(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
      );
}

class QuranBookmarkStore {
  const QuranBookmarkStore._();

  static const String _bookmarkedVersesKey = 'quran_bookmarked_verses';
  static const String _lastSurahKey = 'quran_last_surah';
  static const String _lastAyahKey = 'quran_last_ayah';
  static const String _lastPageKey = 'quran_last_page';

  static String keyFor({
    required int surahNumber,
    required int ayahNumber,
  }) {
    return '$surahNumber:$ayahNumber';
  }

  static String keyForVerse(Verse verse) {
    return keyFor(
      surahNumber: verse.surahNumber,
      ayahNumber: verse.ayahNumber,
    );
  }

  static Future<Set<String>> loadBookmarkedVerseIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_bookmarkedVersesKey) ?? const <String>[])
        .toSet();
  }

  static Future<List<QuranBookmark>> loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarkIds =
        prefs.getStringList(_bookmarkedVersesKey) ?? const <String>[];
    final bookmarks = <QuranBookmark>[];

    for (final bookmarkId in bookmarkIds) {
      final bookmark = _bookmarkFromKey(bookmarkId);
      if (bookmark != null) {
        bookmarks.add(bookmark);
      }
    }

    return bookmarks;
  }

  static Future<QuranBookmark?> loadLastReadingPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final surahNumber = prefs.getInt(_lastSurahKey);
    final ayahNumber = prefs.getInt(_lastAyahKey);
    if (surahNumber == null || ayahNumber == null) return null;

    try {
      final calculatedPageNumber = pageNumberForVerse(
        sura: surahNumber,
        aya: ayahNumber,
      );
      final pageNumber = prefs.getInt(_lastPageKey) ?? calculatedPageNumber;
      RangeError.checkValueInInterval(
        pageNumber,
        1,
        kMushafPageCount,
        'pageNumber',
      );
      return QuranBookmark(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        pageNumber: pageNumber,
      );
    } on RangeError {
      return null;
    }
  }

  static Future<void> saveVerse(Verse verse) async {
    final prefs = await SharedPreferences.getInstance();
    final pageNumber = pageNumberForVerse(
      sura: verse.surahNumber,
      aya: verse.ayahNumber,
    );
    final bookmarkId = keyForVerse(verse);
    final bookmarks =
        prefs.getStringList(_bookmarkedVersesKey) ?? const <String>[];
    final normalizedBookmarks = {
      ...bookmarks,
      bookmarkId,
    }.toList(growable: false);

    await prefs.setStringList(_bookmarkedVersesKey, normalizedBookmarks);
    await prefs.setInt(_lastSurahKey, verse.surahNumber);
    await prefs.setInt(_lastAyahKey, verse.ayahNumber);
    await prefs.setInt(_lastPageKey, pageNumber);
  }

  static Future<bool> removeVerse(Verse verse) {
    return removeBookmarkId(keyForVerse(verse));
  }

  static Future<bool> removeBookmark(QuranBookmark bookmark) {
    return removeBookmarkId(bookmark.id);
  }

  static Future<bool> removeBookmarkId(String bookmarkId) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks =
        prefs.getStringList(_bookmarkedVersesKey) ?? const <String>[];
    if (!bookmarks.contains(bookmarkId)) {
      return false;
    }

    final remaining = [
      for (final id in bookmarks)
        if (id != bookmarkId) id,
    ];

    await prefs.setStringList(_bookmarkedVersesKey, remaining);
    await _repairLastReadingPositionAfterRemoval(
      prefs: prefs,
      removedBookmarkId: bookmarkId,
      remainingBookmarkIds: remaining,
    );
    return true;
  }

  static Future<void> _repairLastReadingPositionAfterRemoval({
    required SharedPreferences prefs,
    required String removedBookmarkId,
    required List<String> remainingBookmarkIds,
  }) async {
    final lastSurah = prefs.getInt(_lastSurahKey);
    final lastAyah = prefs.getInt(_lastAyahKey);
    final removedLastPosition =
        lastSurah != null &&
        lastAyah != null &&
        keyFor(surahNumber: lastSurah, ayahNumber: lastAyah) ==
            removedBookmarkId;

    if (!removedLastPosition) return;

    if (remainingBookmarkIds.isEmpty) {
      await prefs.remove(_lastSurahKey);
      await prefs.remove(_lastAyahKey);
      await prefs.remove(_lastPageKey);
      return;
    }

    final fallbackBookmark = _bookmarkFromKey(remainingBookmarkIds.last);
    if (fallbackBookmark == null) {
      await prefs.remove(_lastSurahKey);
      await prefs.remove(_lastAyahKey);
      await prefs.remove(_lastPageKey);
      return;
    }

    await prefs.setInt(_lastSurahKey, fallbackBookmark.surahNumber);
    await prefs.setInt(_lastAyahKey, fallbackBookmark.ayahNumber);
    await prefs.setInt(_lastPageKey, fallbackBookmark.pageNumber);
  }

  static QuranBookmark? _bookmarkFromKey(String bookmarkId) {
    final parts = bookmarkId.split(':');
    if (parts.length != 2) return null;

    final surahNumber = int.tryParse(parts[0]);
    final ayahNumber = int.tryParse(parts[1]);
    if (surahNumber == null || ayahNumber == null) return null;

    try {
      return QuranBookmark(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        pageNumber: pageNumberForVerse(
          sura: surahNumber,
          aya: ayahNumber,
        ),
      );
    } on RangeError {
      return null;
    }
  }
}
