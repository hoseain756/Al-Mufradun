import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../domain/entities/surah.dart';
import '../../domain/entities/verse.dart';
import '../../domain/repositories/quran_repository.dart';
import '../utils/quran_page_font_loader.dart';

/* ===================================================================
 * Performance caches
 *
 * These static maps eliminate redundant work across page rebuilds.
 * - _verseCache:  verses per page (avoids SQLite on revisit)
 * - _itemCache:   parsed page items (avoids _buildPageItems() on revisit)
 * - _layoutCache: font size + line targets per page (avoids TextPainter)
 * =================================================================== */

final _verseCache = <int, List<Verse>>{};
final _itemCache = <int, List<_PageItem>>{};

class _LayoutKey {
  const _LayoutKey(this.pageNumber, this.w, this.h, this.remaining);

  final int pageNumber;
  final int w;
  final int h;
  final int remaining;

  @override
  bool operator ==(Object other) =>
      other is _LayoutKey &&
      pageNumber == other.pageNumber &&
      w == other.w &&
      h == other.h &&
      remaining == other.remaining;

  @override
  int get hashCode => Object.hash(pageNumber, w, h, remaining);
}

class _CachedLayout {
  const _CachedLayout(this.fontSize, this.lineTargets, this.fontFamily);

  final double fontSize;
  final List<int> lineTargets;
  final String fontFamily;
}

final _layoutCache = <_LayoutKey, _CachedLayout>{};

/// Clears all Quran page caches.
void clearQuranPageCaches() {
  _verseCache.clear();
  _itemCache.clear();
  _layoutCache.clear();
}

/// Pre-cache verses for [pageNumber] so future [QuranTextPage] can be instant.
Future<List<Verse>> precachePageVerses(
  int pageNumber,
  QuranRepository repository,
) async {
  if (_verseCache.containsKey(pageNumber)) {
    return _verseCache[pageNumber]!;
  }
  final verses = await repository.getVersesByPage(pageNumber);
  _verseCache[pageNumber] = verses;
  return verses;
}

/// Pre-compute and cache the full layout (font size + line targets) for a page.
/// After calling this, the first render of that page will skip ALL expensive
/// TextPainter measurements.
Future<void> precomputeQuranPageLayout({
  required int pageNumber,
  required List<Verse> verses,
  required QuranRepository repository,
  required double screenWidth,
  required double screenHeight,
}) async {
  // Same constants as _MushafTextPage
  const gapW = 10.0;
  const gapH = 50.0;
  const padH = 10.0;
  const lineCount = 15;

  final pageWidth = math.max(320.0, screenWidth - gapW);
  final pageHeight = math.max(520.0, screenHeight - gapH);
  final lineHeight = pageHeight / lineCount;
  final textWidth = pageWidth - (padH * 2);
  final pageFont = AppTheme.getQuranPageFont(pageNumber);

  // Build & cache page items
  final items = _buildPageItemsForVerses(verses, repository);
  _itemCache[pageNumber] = items;

  final verseRuns = items.whereType<_VerseRunItem>().toList();
  final controlLineCount = items.length - verseRuns.length;
  final remainingLineCount = math.max(1, lineCount - controlLineCount);

  // Build layout key & cache
  final layoutKey = _LayoutKey(
    pageNumber,
    textWidth.round(),
    lineHeight.round(),
    remainingLineCount,
  );
  if (_layoutCache.containsKey(layoutKey)) return;

  final fontSize = _MushafTextPage._resolveFontSize(
    pageNumber: pageNumber,
    pageFont: pageFont,
    verseRuns: verseRuns,
    maxWidth: textWidth,
    targetLineCount: remainingLineCount,
    lineHeight: lineHeight,
  );
  final lineTargets = _MushafTextPage._resolveLineTargets(
    pageFont: pageFont,
    fontSize: fontSize,
    verseRuns: verseRuns,
    maxWidth: textWidth,
    targetLineCount: remainingLineCount,
    lineHeight: lineHeight,
  );

  _layoutCache[layoutKey] = _CachedLayout(fontSize, lineTargets, pageFont);
}

/* ===================================================================
 * QuranTextPage — wraps each mushaf page in a zoomable container
 * =================================================================== */

class QuranTextPage extends StatefulWidget {
  const QuranTextPage({
    super.key,
    required this.pageNumber,
    required this.repository,
    required this.onVerseLongPressed,
    this.bookmarkedVerseIds = const <String>{},
    this.focusedVerseId,
  });

  final int pageNumber;
  final QuranRepository repository;
  final ValueChanged<Verse> onVerseLongPressed;
  final Set<String> bookmarkedVerseIds;
  final int? focusedVerseId;

  @override
  State<QuranTextPage> createState() => _QuranTextPageState();
}

class _QuranTextPageState extends State<QuranTextPage> {
  late Future<List<Verse>> _pageFuture;
  int? _selectedVerseId;

  @override
  void initState() {
    super.initState();
    _selectedVerseId = widget.focusedVerseId;
    _pageFuture = _loadPage();
  }

  @override
  void didUpdateWidget(covariant QuranTextPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber ||
        oldWidget.repository != widget.repository) {
      _pageFuture = _loadPage();
      _selectedVerseId = widget.focusedVerseId;
    } else if (oldWidget.focusedVerseId != widget.focusedVerseId) {
      _selectedVerseId = widget.focusedVerseId;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<List<Verse>> _loadPage() async {
    // 1. Hit verse cache first — instant on revisit
    final cached = _verseCache[widget.pageNumber];
    if (cached != null) return cached;

    // 2. Fire font loading in parallel so it doesn't block rendering
    QuranPageFontLoader.loadPageFont(widget.pageNumber);

    // 3. Fetch verses from DB
    final verses =
        await widget.repository.getVersesByPage(widget.pageNumber);
    _verseCache[widget.pageNumber] = verses;
    return verses;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: FutureBuilder<List<Verse>>(
        future: _pageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            );
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            final colorScheme = Theme.of(context).colorScheme;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'تعذر تحميل الصفحة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.error,
                        fontFamily: AppTheme.handicraftsFont,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return _MushafTextPage(
            pageNumber: widget.pageNumber,
            verses: snapshot.data!,
            repository: widget.repository,
            selectedVerseId: _selectedVerseId,
            bookmarkedVerseIds: widget.bookmarkedVerseIds,
            onVerseLongPressed: (verse) {
              setState(() => _selectedVerseId = verse.id);
              widget.onVerseLongPressed(verse);
            },
          );
        },
      ),
    );
  }
}

/* ===================================================================
 * _MushafTextPage — renders one mushaf spread (15 fixed lines)
 * =================================================================== */

class _MushafTextPage extends StatelessWidget {
  const _MushafTextPage({
    required this.pageNumber,
    required this.verses,
    required this.repository,
    required this.selectedVerseId,
    required this.bookmarkedVerseIds,
    required this.onVerseLongPressed,
  });

  static const int mushafLineCount = 15;
  static const double screenHorizontalGap = 10;
  static const double screenVerticalGap = 50;
  static const double horizontalPadding = 10;
  static const String _basmala = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

  final int pageNumber;
  final List<Verse> verses;
  final QuranRepository repository;
  final int? selectedVerseId;
  final Set<String> bookmarkedVerseIds;
  final ValueChanged<Verse> onVerseLongPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pageFont = AppTheme.getQuranPageFont(pageNumber);
    final items = _buildPageItemsCached();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth =
              constraints.maxWidth.isFinite ? constraints.maxWidth : 390.0;
          final availableHeight =
              constraints.maxHeight.isFinite ? constraints.maxHeight : 720.0;
          final pageWidth = math.max(
            320.0,
            availableWidth - screenHorizontalGap,
          );
          final pageHeight = math.max(
            520.0,
            availableHeight - screenVerticalGap,
          );
          final lineHeight = pageHeight / mushafLineCount;
          final textWidth = pageWidth - (horizontalPadding * 2);
          final verseRuns = items.whereType<_VerseRunItem>().toList();
          final controlLineCount = items.length - verseRuns.length;
          final remainingLineCount = math.max(
            1,
            mushafLineCount - controlLineCount,
          );

          // ---- cached layout lookup ----
          final layoutKey = _LayoutKey(
            pageNumber,
            textWidth.round(),
            lineHeight.round(),
            remainingLineCount,
          );
          final cached = _layoutCache[layoutKey];
          double fontSize;
          List<int> lineTargets;

          if (cached != null && cached.fontFamily == pageFont) {
            fontSize = cached.fontSize;
            lineTargets = cached.lineTargets;
          } else if (_layoutCache.isNotEmpty) {
            // Use any cached layout for a different page as seed size,
            // then compute the actual layout for this page
            final seed = _layoutCache.entries.first;
            fontSize = _resolveFontSize(
              pageNumber: pageNumber,
              pageFont: pageFont,
              verseRuns: verseRuns,
              maxWidth: textWidth,
              targetLineCount: remainingLineCount,
              lineHeight: lineHeight,
              seedFontSize: seed.value.fontSize,
            );
            lineTargets = _resolveLineTargets(
              pageFont: pageFont,
              fontSize: fontSize,
              verseRuns: verseRuns,
              maxWidth: textWidth,
              targetLineCount: remainingLineCount,
              lineHeight: lineHeight,
            );
            _layoutCache[layoutKey] = _CachedLayout(
              fontSize,
              lineTargets,
              pageFont,
            );
          } else {
            fontSize = _resolveFontSize(
              pageNumber: pageNumber,
              pageFont: pageFont,
              verseRuns: verseRuns,
              maxWidth: textWidth,
              targetLineCount: remainingLineCount,
              lineHeight: lineHeight,
            );
            lineTargets = _resolveLineTargets(
              pageFont: pageFont,
              fontSize: fontSize,
              verseRuns: verseRuns,
              maxWidth: textWidth,
              targetLineCount: remainingLineCount,
              lineHeight: lineHeight,
            );
            _layoutCache[layoutKey] = _CachedLayout(
              fontSize,
              lineTargets,
              pageFont,
            );
          }

          var runIndex = 0;

          return Center(
            child: RepaintBoundary(
              child: SizedBox(
                width: pageWidth,
                height: pageHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final item in items)
                        switch (item) {
                          _HeaderItem(:final surah) => _SurahHeaderLine(
                              surah: surah,
                              lineHeight: lineHeight,
                            ),
                          _BasmalaItem() => _BasmalaLine(
                              text: _basmala,
                              lineHeight: lineHeight,
                            ),
                          _VerseRunItem() => _VerseRun(
                              pageFont: pageFont,
                              fontSize: fontSize,
                              lineHeight: lineHeight,
                              targetLineCount: lineTargets[runIndex++],
                              item: item,
                              textColor: colorScheme.onSurface,
                              selectedVerseId: selectedVerseId,
                              bookmarkedVerseIds: bookmarkedVerseIds,
                              highlightColor: colorScheme.primaryContainer
                                  .withValues(alpha: 0.52),
                              bookmarkColor: colorScheme.secondaryContainer
                                  .withValues(alpha: 0.38),
                              maxWidth: textWidth,
                              onVerseLongPressed: onVerseLongPressed,
                            ),
                        },
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---- cached page items ----

  List<_PageItem> _buildPageItemsCached() {
    final cached = _itemCache[pageNumber];
    if (cached != null) return cached;

    final items = _buildPageItemsForVerses(verses, repository);
    _itemCache[pageNumber] = items;
    return items;
  }

  // ---- font size / line-count resolution ----

  static double _resolveFontSize({
    required int pageNumber,
    required String pageFont,
    required List<_VerseRunItem> verseRuns,
    required double maxWidth,
    required int targetLineCount,
    required double lineHeight,
    double? seedFontSize,
  }) {
    final baseSize =
        seedFontSize ?? _baseFontSizeForPage(pageNumber, lineHeight);
    final baseLineCount = _totalMeasuredLineCount(
      pageFont: pageFont,
      fontSize: baseSize,
      verseRuns: verseRuns,
      maxWidth: maxWidth,
      lineHeight: lineHeight,
    );
    if (baseLineCount <= targetLineCount) {
      return baseSize;
    }

    // Binary search — reduce to 5 iterations (was 10)
    var low = math.min(14.0, baseSize);
    var high = baseSize;
    for (var i = 0; i < 5; i++) {
      final mid = (low + high) / 2;
      final lineCount = _totalMeasuredLineCount(
        pageFont: pageFont,
        fontSize: mid,
        verseRuns: verseRuns,
        maxWidth: maxWidth,
        lineHeight: lineHeight,
      );
      if (lineCount > targetLineCount) {
        high = mid;
      } else {
        low = mid;
      }
    }
    return low;
  }

  static List<int> _resolveLineTargets({
    required String pageFont,
    required double fontSize,
    required List<_VerseRunItem> verseRuns,
    required double maxWidth,
    required int targetLineCount,
    required double lineHeight,
  }) {
    if (verseRuns.isEmpty) {
      return const [];
    }

    final counts = [
      for (final run in verseRuns)
        math.max(
          1,
          _measureLineCount(
            pageFont: pageFont,
            fontSize: fontSize,
            item: run,
            maxWidth: maxWidth,
            lineHeight: lineHeight,
          ),
        ),
    ];

    final total = counts.fold(0, (sum, count) => sum + count);
    if (total < targetLineCount) {
      counts[counts.length - 1] += targetLineCount - total;
    } else if (total > targetLineCount) {
      var overflow = total - targetLineCount;
      for (var index = counts.length - 1; index >= 0 && overflow > 0; index--) {
        final removable = math.max(0, counts[index] - 1);
        final removed = math.min(removable, overflow);
        counts[index] -= removed;
        overflow -= removed;
      }
    }

    return counts;
  }

  static int _totalMeasuredLineCount({
    required String pageFont,
    required double fontSize,
    required List<_VerseRunItem> verseRuns,
    required double maxWidth,
    required double lineHeight,
  }) {
    return verseRuns.fold(
      0,
      (total, run) =>
          total +
          _measureLineCount(
            pageFont: pageFont,
            fontSize: fontSize,
            item: run,
            maxWidth: maxWidth,
            lineHeight: lineHeight,
          ),
    );
  }

  static int _measureLineCount({
    required String pageFont,
    required double fontSize,
    required _VerseRunItem item,
    required double maxWidth,
    required double lineHeight,
  }) {
    final painter = TextPainter(
      text: _buildVerseTextSpan(
        item: item,
        pageFont: pageFont,
        fontSize: fontSize,
        color: Colors.black,
        lineHeight: lineHeight,
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
      locale: const Locale('ar'),
      strutStyle: _strutStyle(
        pageFont: pageFont,
        fontSize: fontSize,
        lineHeight: lineHeight,
      ),
    )..layout(maxWidth: maxWidth);

    final lineCount = painter.computeLineMetrics().length;
    painter.dispose();
    return lineCount;
  }

  // ---- text-building helpers (all static) ----

  static TextSpan _buildVerseTextSpan({
    required _VerseRunItem item,
    required String pageFont,
    required double fontSize,
    required Color color,
    required double lineHeight,
    int? selectedVerseId,
    Color? highlightColor,
    Set<String> bookmarkedVerseIds = const <String>{},
    Color? bookmarkColor,
  }) {
    return TextSpan(
      style: TextStyle(
        color: color,
        fontFamily: pageFont,
        fontSize: fontSize,
        height: lineHeight / fontSize,
        letterSpacing: 0,
        wordSpacing: 0,
      ),
      children: [
        for (final piece in _buildTextPieces(item))
          TextSpan(
            text: piece.text,
            style: _styleForPiece(
              piece: piece,
              selectedVerseId: selectedVerseId,
              bookmarkedVerseIds: bookmarkedVerseIds,
              highlightColor: highlightColor,
              bookmarkColor: bookmarkColor,
            ),
          ),
      ],
    );
  }

  static TextStyle? _styleForPiece({
    required _VerseTextPiece piece,
    required int? selectedVerseId,
    required Set<String> bookmarkedVerseIds,
    required Color? highlightColor,
    required Color? bookmarkColor,
  }) {
    if (piece.verse.id == selectedVerseId) {
      return TextStyle(backgroundColor: highlightColor);
    }

    final verseKey = '${piece.verse.surahNumber}:${piece.verse.ayahNumber}';
    if (bookmarkedVerseIds.contains(verseKey)) {
      return TextStyle(backgroundColor: bookmarkColor);
    }

    return null;
  }

  static List<_VerseTextPiece> _buildTextPieces(_VerseRunItem item) {
    var offset = 0;
    final pieces = <_VerseTextPiece>[];

    for (var index = 0; index < item.verses.length; index++) {
      final verse = item.verses[index];
      final text = _formatQcfText(
        verse.qcfText,
        isSegmentStart: item.firstVerseStartsSegment && index == 0,
      );
      final displayText = index == item.verses.length - 1 ? text : '$text ';
      pieces.add(
        _VerseTextPiece(
          verse: verse,
          text: displayText,
          start: offset,
          end: offset + displayText.length,
        ),
      );
      offset += displayText.length;
    }

    return pieces;
  }

  static String _formatQcfText(
    String value, {
    required bool isSegmentStart,
  }) {
    final text = value.trim();
    if (!isSegmentStart || text.length <= 1) {
      return text;
    }
    return '${text.substring(0, 1)}\u200A${text.substring(1)}';
  }

  static StrutStyle _strutStyle({
    required String pageFont,
    required double fontSize,
    required double lineHeight,
  }) {
    return StrutStyle(
      fontFamily: pageFont,
      fontSize: fontSize,
      height: lineHeight / fontSize,
      forceStrutHeight: true,
    );
  }

  static double _baseFontSizeForPage(int pageNumber, double lineHeight) {
    if (pageNumber <= 2) return lineHeight * 0.78;
    if (pageNumber == 145 ||
        pageNumber == 201 ||
        pageNumber == 532 ||
        pageNumber == 533) {
      return lineHeight * 0.6;
    }
    return lineHeight * 0.68;
  }
}

// ---- Shared: _buildPageItemsForVerses (package-visible, used by precompute) ----

List<_PageItem> _buildPageItemsForVerses(
  List<Verse> verses,
  QuranRepository repository,
) {
  final items = <_PageItem>[];
  var startIndex = 0;
  var firstVerseStartsSegment = true;

  for (var index = 0; index < verses.length; index++) {
    final verse = verses[index];
    final startsSurah = verse.ayahNumber == 1;

    if (startsSurah && index != startIndex) {
      items.add(
        _VerseRunItem(
          verses: verses.sublist(startIndex, index),
          firstVerseStartsSegment: firstVerseStartsSegment,
        ),
      );
      startIndex = index;
      firstVerseStartsSegment = true;
    }

    if (startsSurah) {
      final surah = repository.getSurahById(verse.surahNumber);
      if (surah != null) {
        items.add(_HeaderItem(surah));
      }
      if (verse.surahNumber != 1 && verse.surahNumber != 9) {
        items.add(const _BasmalaItem());
      }
    }
  }

  items.add(
    _VerseRunItem(
      verses: verses.sublist(startIndex),
      firstVerseStartsSegment: firstVerseStartsSegment,
    ),
  );

  return items;
}

/* ===================================================================
 * Page item types
 * =================================================================== */

sealed class _PageItem {
  const _PageItem();
}

class _HeaderItem extends _PageItem {
  const _HeaderItem(this.surah);

  final Surah surah;
}

class _BasmalaItem extends _PageItem {
  const _BasmalaItem();
}

class _VerseRunItem extends _PageItem {
  const _VerseRunItem({
    required this.verses,
    required this.firstVerseStartsSegment,
  });

  final List<Verse> verses;
  final bool firstVerseStartsSegment;
}

class _VerseTextPiece {
  const _VerseTextPiece({
    required this.verse,
    required this.text,
    required this.start,
    required this.end,
  });

  final Verse verse;
  final String text;
  final int start;
  final int end;
}

/* ===================================================================
 * _VerseRun — renders one run of verses as a RichText
 * =================================================================== */

class _VerseRun extends StatelessWidget {
  const _VerseRun({
    required this.pageFont,
    required this.fontSize,
    required this.lineHeight,
    required this.targetLineCount,
    required this.item,
    required this.textColor,
    required this.selectedVerseId,
    required this.bookmarkedVerseIds,
    required this.highlightColor,
    required this.bookmarkColor,
    required this.maxWidth,
    required this.onVerseLongPressed,
  });

  final String pageFont;
  final double fontSize;
  final double lineHeight;
  final int targetLineCount;
  final _VerseRunItem item;
  final Color textColor;
  final int? selectedVerseId;
  final Set<String> bookmarkedVerseIds;
  final Color highlightColor;
  final Color bookmarkColor;
  final double maxWidth;
  final ValueChanged<Verse> onVerseLongPressed;

  @override
  Widget build(BuildContext context) {
    if (item.verses.isEmpty) {
      return const SizedBox.shrink();
    }

    final textSpan = _MushafTextPage._buildVerseTextSpan(
      item: item,
      pageFont: pageFont,
      fontSize: fontSize,
      color: textColor,
      lineHeight: lineHeight,
      selectedVerseId: selectedVerseId,
      bookmarkedVerseIds: bookmarkedVerseIds,
      highlightColor: highlightColor,
      bookmarkColor: bookmarkColor,
    );

    return SizedBox(
      height: targetLineCount * lineHeight,
      width: double.infinity,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPressStart: (details) {
          final verse = _verseAtOffset(
            position: details.localPosition,
            textSpan: textSpan,
          );
          if (verse != null) {
            onVerseLongPressed(verse);
          }
        },
        child: RichText(
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.justify,
          softWrap: true,
          locale: const Locale('ar'),
          strutStyle: _MushafTextPage._strutStyle(
            pageFont: pageFont,
            fontSize: fontSize,
            lineHeight: lineHeight,
          ),
          text: textSpan,
        ),
      ),
    );
  }

  Verse? _verseAtOffset({
    required Offset position,
    required TextSpan textSpan,
  }) {
    final painter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
      locale: const Locale('ar'),
      strutStyle: _MushafTextPage._strutStyle(
        pageFont: pageFont,
        fontSize: fontSize,
        lineHeight: lineHeight,
      ),
    )..layout(maxWidth: maxWidth);

    final lineMetrics = painter.computeLineMetrics();
    if (lineMetrics.isEmpty || position.dy > lineMetrics.length * lineHeight) {
      painter.dispose();
      return null;
    }

    final textPosition = painter.getPositionForOffset(position);
    final offset = textPosition.offset;
    final pieces = _MushafTextPage._buildTextPieces(item);
    painter.dispose();

    for (final piece in pieces) {
      if (offset >= piece.start && offset <= piece.end) {
        return piece.verse;
      }
    }
    return null;
  }
}

/* ===================================================================
 * _SurahHeaderLine
 * =================================================================== */

class _SurahHeaderLine extends StatelessWidget {
  const _SurahHeaderLine({
    required this.surah,
    required this.lineHeight,
  });

  final Surah surah;
  final double lineHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: lineHeight,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.42),
              width: 1.1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.24),
                ),
              ),
              child: Center(
                child: Text(
                  'سورة ${surah.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontFamily: AppTheme.handicraftsFont,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ===================================================================
 * _BasmalaLine
 * =================================================================== */

class _BasmalaLine extends StatelessWidget {
  const _BasmalaLine({
    required this.text,
    required this.lineHeight,
  });

  final String text;
  final double lineHeight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: lineHeight,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Center(
          child: Text(
            text,
            maxLines: 1,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontFamily: AppTheme.uthmanicHafsFont,
              fontSize: lineHeight * 0.56,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}



