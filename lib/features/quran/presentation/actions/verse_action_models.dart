import 'package:flutter/widgets.dart';

import '../../domain/entities/surah.dart';
import '../../domain/entities/verse.dart';

enum VerseActionType {
  copy,
  shareText,
  shareImage,
  bookmark,
  removeBookmark,
  tafsir,
  notes,
  highlight,
}

class VerseActionContext {
  VerseActionContext.single({
    required Verse verse,
    required Surah surah,
    Set<String> bookmarkedVerseIds = const <String>{},
  })  : verse = verse,
        surah = surah,
        startVerse = verse,
        startSurah = surah,
        endVerse = verse,
        endSurah = surah,
        verses = [verse],
        bookmarkedVerseIds = Set.unmodifiable(bookmarkedVerseIds);

  VerseActionContext.range({
    required this.startVerse,
    required this.startSurah,
    required this.endVerse,
    required this.endSurah,
    required List<Verse> verses,
    Set<String> bookmarkedVerseIds = const <String>{},
  })  : verse = startVerse,
        surah = startSurah,
        verses = List.unmodifiable(verses),
        bookmarkedVerseIds = Set.unmodifiable(bookmarkedVerseIds);

  final Verse verse;
  final Surah surah;
  final Verse startVerse;
  final Surah startSurah;
  final Verse endVerse;
  final Surah endSurah;
  final List<Verse> verses;
  final Set<String> bookmarkedVerseIds;

  bool get isRange => verses.length > 1;

  bool get isStartVerseBookmarked {
    return bookmarkedVerseIds.contains(
      '${startVerse.surahNumber}:${startVerse.ayahNumber}',
    );
  }
}

class VerseActionCommand {
  const VerseActionCommand({
    required this.type,
    required this.label,
    required this.icon,
    required this.order,
    required this.analyticsName,
    required this.isEnabled,
    this.disabledReason,
  });

  final VerseActionType type;
  final String label;
  final IconData icon;
  final int order;
  final String analyticsName;
  final bool isEnabled;
  final String? disabledReason;
}

class VerseActionAnalyticsEvent {
  const VerseActionAnalyticsEvent({
    required this.type,
    required this.analyticsName,
    required this.surahId,
    required this.ayahNumber,
    required this.verseId,
  });

  final VerseActionType type;
  final String analyticsName;
  final int surahId;
  final int ayahNumber;
  final int verseId;
}

typedef VerseActionTracker = void Function(VerseActionAnalyticsEvent event);
