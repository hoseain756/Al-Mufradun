import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../../theme/app_icons.dart';
import '../../../../theme/app_theme.dart';
import '../../data/quran_repository_factory.dart';
import '../../data/static/mushaf_page_mapping.dart';
import '../../domain/entities/surah.dart';
import '../../domain/entities/verse.dart';
import '../../domain/repositories/quran_repository.dart';
import '../utils/arabic_number_formatter.dart';
import '../utils/quran_bookmark_store.dart';
import '../utils/quran_page_font_loader.dart';
import '../widgets/quran_text_page.dart';
import '../widgets/verse_action_sheet.dart';

/// The main reader screen that displays page-shaped Quran text using QCF page
/// fonts and the local Quran database.
class SurahReaderScreen extends StatefulWidget {
  SurahReaderScreen({
    super.key,
    required this.surah,
    QuranRepository? repository,
  }) : repository = repository ?? createQuranRepository();

  final Surah surah;
  final QuranRepository repository;

  @override
  State<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends State<SurahReaderScreen> {
  late PageController _pageController;
  late int _currentPageNumber;
  QuranBookmark? _lastBookmark;
  List<QuranBookmark> _bookmarks = const <QuranBookmark>[];
  Set<String> _bookmarkedVerseIds = const <String>{};
  int? _focusedPageNumber;
  int? _focusedVerseId;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initPageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookmarkState();
      _preloadAroundPage(_currentPageNumber);
    });
  }

  @override
  void didUpdateWidget(covariant SurahReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.surah.id != widget.surah.id) {
      _pageController.dispose();
      _initPageController();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadBookmarkState();
        _preloadAroundPage(_currentPageNumber);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _initPageController() {
    _currentPageNumber = pageNumberForVerse(
      sura: widget.surah.id,
      aya: 1,
    );
    _pageController = PageController(
      initialPage: _currentPageNumber - 1,
      keepPage: false,
    );
  }

  void _preloadAroundPage(int pageNumber) {
    // Preload fonts for a wider range (±10 pages)
    QuranPageFontLoader.preloadRange(pageNumber, range: 10);

    // Eagerly cache verses AND full layout for the next 20 pages
    // so they render instantly when the user scrolls to them
    _precomputeAhead(pageNumber);
  }

  Future<void> _precomputeAhead(int currentPage) async {
    // Get screen dimensions once (locked in portrait)
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Build a list of upcoming pages to precompute (up to 20 ahead)
    final pages = <int>[];
    for (var offset = 1; offset <= 20; offset++) {
      final forward = currentPage + offset;
      final backward = currentPage - offset;
      if (forward <= kMushafPageCount) pages.add(forward);
      if (backward >= 1) pages.add(backward);
    }

    // Process in small batches to avoid blocking the event loop
    for (final p in pages) {
      // Skip if layout is already cached
      final verses = await precachePageVerses(p, widget.repository);
      await precomputeQuranPageLayout(
        pageNumber: p,
        verses: verses,
        repository: widget.repository,
        screenWidth: screenWidth,
        screenHeight: screenHeight,
      );
    }
  }

  Future<void> _loadBookmarkState() async {
    final bookmark = await QuranBookmarkStore.loadLastReadingPosition();
    final bookmarks = await QuranBookmarkStore.loadBookmarks();
    final bookmarkedVerseIds =
        await QuranBookmarkStore.loadBookmarkedVerseIds();

    if (!mounted) return;
    setState(() {
      _lastBookmark = bookmark;
      _bookmarks = bookmarks;
      _bookmarkedVerseIds = bookmarkedVerseIds;
    });
  }

  void _onPageChanged(int index) {
    final pageNumber = index + 1;
    setState(() {
      _currentPageNumber = pageNumber;
      if (_focusedPageNumber != pageNumber) {
        _focusedPageNumber = null;
        _focusedVerseId = null;
      }
    });
    _preloadAroundPage(pageNumber);
  }

  void _goToPage(int pageNumber, {int? focusedVerseId}) {
    final targetPage = pageNumber.clamp(1, kMushafPageCount).toInt();
    setState(() {
      _focusedPageNumber = focusedVerseId == null ? null : targetPage;
      _focusedVerseId = focusedVerseId;
    });
    _preloadAroundPage(targetPage);
    _pageController.animateToPage(
      targetPage - 1,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  /// Gets the Juz' number for a specific page in standard Mushaf
  int _juzNumberForPage(int page) {
    if (page <= 21) return 1;
    if (page <= 41) return 2;
    if (page <= 61) return 3;
    if (page <= 81) return 4;
    if (page <= 101) return 5;
    if (page <= 121) return 6;
    if (page <= 141) return 7;
    if (page <= 161) return 8;
    if (page <= 181) return 9;
    if (page <= 201) return 10;
    if (page <= 221) return 11;
    if (page <= 241) return 12;
    if (page <= 261) return 13;
    if (page <= 281) return 14;
    if (page <= 301) return 15;
    if (page <= 321) return 16;
    if (page <= 341) return 17;
    if (page <= 361) return 18;
    if (page <= 381) return 19;
    if (page <= 401) return 20;
    if (page <= 421) return 21;
    if (page <= 441) return 22;
    if (page <= 461) return 23;
    if (page <= 481) return 24;
    if (page <= 501) return 25;
    if (page <= 521) return 26;
    if (page <= 541) return 27;
    if (page <= 561) return 28;
    if (page <= 581) return 29;
    return 30;
  }

  Future<void> _showVerseActions(Verse verse) async {
    final surah = widget.repository.getSurahById(verse.surahNumber);
    if (surah == null) return;

    await VerseActionSheet.show(
      context: context,
      verse: verse,
      surah: surah,
      bookmarkedVerseIds: _bookmarkedVerseIds,
    );
    await _loadBookmarkState();
  }

  Future<void> _openBookmarks() async {
    await _loadBookmarkState();
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      builder: (sheetContext) {
        return _QuranBookmarksSheet(
          repository: widget.repository,
          bookmarks: _bookmarks,
          onOpen: (bookmark) {
            Navigator.of(sheetContext).pop();
            _goToPage(bookmark.pageNumber);
          },
          onChanged: _loadBookmarkState,
        );
      },
    );
  }

  Future<void> _openSearch() async {
    final target = await showModalBottomSheet<_ReaderNavigationTarget>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      builder: (_) {
        return _QuranSearchSheet(
          repository: widget.repository,
          currentSurahId: widget.surah.id,
        );
      },
    );

    if (target == null || !mounted) return;
    _goToPage(
      target.pageNumber,
      focusedVerseId: target.focusedVerseId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine the surah active on the current page to display in top bar
    final currentPageInfo = pageInfoForPage(_currentPageNumber);
    final activeSurah = widget.repository.getSurahById(
      currentPageInfo.startSura,
    );
    final surahName = activeSurah?.name ?? widget.surah.name;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        backgroundColor: colorScheme.surface,
        body: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  setState(() {
                    _showControls = !_showControls;
                  });
                },
                child: PageView.builder(
                  key: ValueKey('mushaf-reader-${widget.surah.id}'),
                  controller: _pageController,
                  itemCount: kMushafPageCount,
                  physics: const BouncingScrollPhysics(
                    parent: PageScrollPhysics(),
                  ),
                  allowImplicitScrolling: true,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    final pageNumber = index + 1;
                    return QuranTextPage(
                      key: ValueKey('mushaf-text-page-$pageNumber'),
                      pageNumber: pageNumber,
                      repository: widget.repository,
                      bookmarkedVerseIds: _bookmarkedVerseIds,
                      focusedVerseId: pageNumber == _focusedPageNumber
                          ? _focusedVerseId
                          : null,
                      onVerseLongPressed: _showVerseActions,
                    );
                  },
                ),
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              top: _showControls ? 0.0 : -110.0,
              left: 0.0,
              right: 0.0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.85),
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: SizedBox(
                        height: 56,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(OctIcons.arrow_right),
                              tooltip: 'رجوع',
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'سورة $surahName',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: AppTheme.handicraftsFont,
                                  color: colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(OctIcons.search),
                              tooltip: 'بحث',
                              onPressed: _openSearch,
                            ),
                            IconButton(
                              icon: const Icon(OctIcons.star),
                              tooltip: 'الآيات المحفوظة',
                              color: _lastBookmark == null
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.primary,
                              onPressed: _openBookmarks,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              bottom: _showControls ? 0.0 : -160.0,
              left: 0.0,
              right: 0.0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.85),
                      border: Border(
                        top: BorderSide(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'الجزء ${ArabicNumberFormatter.format(_juzNumberForPage(_currentPageNumber))}',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: AppTheme.handicraftsFont,
                                    ),
                                  ),
                                ),
                                Text(
                                  'الصفحة ${ArabicNumberFormatter.format(_currentPageNumber)}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: AppTheme.handicraftsFont,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  color: colorScheme.primary,
                                  onPressed: _currentPageNumber < kMushafPageCount
                                      ? () => _goToPage(_currentPageNumber + 1)
                                      : null,
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 4,
                                      activeTrackColor: colorScheme.primary,
                                      inactiveTrackColor:
                                          colorScheme.primary.withValues(
                                        alpha: 0.2,
                                      ),
                                      thumbColor: colorScheme.primary,
                                      thumbShape:
                                          const RoundSliderThumbShape(
                                        enabledThumbRadius: 6,
                                      ),
                                      overlayColor:
                                          colorScheme.primary.withValues(
                                        alpha: 0.12,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                        overlayRadius: 14,
                                      ),
                                    ),
                                    child: Slider(
                                      value: _currentPageNumber.toDouble(),
                                      min: 1,
                                      max: kMushafPageCount.toDouble(),
                                      onChanged: (value) {
                                        setState(() {
                                          _currentPageNumber = value.round();
                                        });
                                      },
                                      onChangeEnd: (value) {
                                        _goToPage(value.round());
                                      },
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  color: colorScheme.primary,
                                  onPressed: _currentPageNumber > 1
                                      ? () => _goToPage(_currentPageNumber - 1)
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderNavigationTarget {
  const _ReaderNavigationTarget({
    required this.pageNumber,
    this.focusedVerseId,
  });

  final int pageNumber;
  final int? focusedVerseId;
}

class _SavedVerseItem {
  const _SavedVerseItem({
    required this.bookmark,
    required this.surah,
    required this.verse,
  });

  final QuranBookmark bookmark;
  final Surah surah;
  final Verse verse;
}

class _QuranBookmarksSheet extends StatefulWidget {
  const _QuranBookmarksSheet({
    required this.repository,
    required this.bookmarks,
    required this.onOpen,
    required this.onChanged,
  });

  final QuranRepository repository;
  final List<QuranBookmark> bookmarks;
  final ValueChanged<QuranBookmark> onOpen;
  final Future<void> Function() onChanged;

  @override
  State<_QuranBookmarksSheet> createState() => _QuranBookmarksSheetState();
}

class _QuranBookmarksSheetState extends State<_QuranBookmarksSheet> {
  late List<QuranBookmark> _bookmarks;
  late Future<List<_SavedVerseItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _bookmarks = widget.bookmarks.toList(growable: true);
    _itemsFuture = _loadItems();
  }

  Future<List<_SavedVerseItem>> _loadItems() async {
    final pageCache = <int, List<Verse>>{};
    final items = <_SavedVerseItem>[];

    for (final bookmark in _bookmarks.reversed) {
      final verses = pageCache[bookmark.pageNumber] ??
          await widget.repository.getVersesByPage(bookmark.pageNumber);
      pageCache[bookmark.pageNumber] = verses;

      Verse? verse;
      for (final candidate in verses) {
        if (candidate.surahNumber == bookmark.surahNumber &&
            candidate.ayahNumber == bookmark.ayahNumber) {
          verse = candidate;
          break;
        }
      }

      final surah = widget.repository.getSurahById(bookmark.surahNumber);
      if (verse != null && surah != null) {
        items.add(
          _SavedVerseItem(
            bookmark: bookmark,
            surah: surah,
            verse: verse,
          ),
        );
      }
    }

    return items;
  }

  Future<void> _removeBookmark(QuranBookmark bookmark) async {
    await QuranBookmarkStore.removeBookmark(bookmark);
    await widget.onChanged();
    if (!mounted) return;

    setState(() {
      _bookmarks.removeWhere((item) => item.id == bookmark.id);
      _itemsFuture = _loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'الآيات المحفوظة',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTheme.handicraftsFont,
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<_SavedVerseItem>>(
                future: _itemsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final items = snapshot.data ?? const <_SavedVerseItem>[];
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Text(
                        'لا توجد آيات محفوظة',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 440),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => Divider(
                        color: colorScheme.outlineVariant,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final ayahNumber = ArabicNumberFormatter.format(
                          item.verse.ayahNumber,
                        );
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            OctIcons.star,
                            color: colorScheme.primary,
                          ),
                          title: Text(
                            'سورة ${item.surah.name} • الآية $ayahNumber',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            item.verse.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: colorScheme.error,
                            tooltip: 'إزالة الحفظ',
                            onPressed: () => _removeBookmark(item.bookmark),
                          ),
                          onTap: () => widget.onOpen(item.bookmark),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuranSearchResult {
  const _QuranSearchResult({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.pageNumber,
    this.verse,
  });

  final String key;
  final String title;
  final String subtitle;
  final int pageNumber;
  final Verse? verse;

  _ReaderNavigationTarget get target {
    return _ReaderNavigationTarget(
      pageNumber: pageNumber,
      focusedVerseId: verse?.id,
    );
  }
}

class _QuranSearchSheet extends StatefulWidget {
  const _QuranSearchSheet({
    required this.repository,
    required this.currentSurahId,
  });

  final QuranRepository repository;
  final int currentSurahId;

  @override
  State<_QuranSearchSheet> createState() => _QuranSearchSheetState();
}

class _QuranSearchSheetState extends State<_QuranSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<_QuranSearchResult> _results = const [];
  bool _isLoading = false;
  int _searchToken = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      _runSearch(value);
    });
  }

  Future<void> _runSearch(String value) async {
    final query = value.trim();
    final token = ++_searchToken;

    if (query.isEmpty) {
      setState(() {
        _isLoading = false;
        _results = const [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final results = await _buildResults(query);
    if (!mounted || token != _searchToken) return;

    setState(() {
      _isLoading = false;
      _results = results;
    });
  }

  Future<List<_QuranSearchResult>> _buildResults(String query) async {
    final results = <_QuranSearchResult>[];
    final resultKeys = <String>{};
    final cleanedQuery = _cleanQuery(query);
    final queryNumber = _parseLocalizedInt(cleanedQuery);
    final queryNumbers = _parseAllLocalizedInts(cleanedQuery);
    final queryWithoutNumbers =
        _toEnglishDigits(cleanedQuery).replaceAll(RegExp(r'\d+'), '').trim();
    final normalizedQuery = _normalizeArabic(
      queryWithoutNumbers.isEmpty ? cleanedQuery : queryWithoutNumbers,
    );

    void addResult(_QuranSearchResult result) {
      if (resultKeys.add(result.key)) {
        results.add(result);
      }
    }

    if (queryNumber != null) {
      if (queryNumber >= 1 && queryNumber <= kMushafPageCount) {
        addResult(_pageResult(queryNumber));
      }

      final surah = widget.repository.getSurahById(queryNumber);
      if (surah != null) {
        addResult(_surahResult(surah));
      }

      final currentSurah = widget.repository.getSurahById(
        widget.currentSurahId,
      );
      if (currentSurah != null &&
          queryNumber >= 1 &&
          queryNumber <= currentSurah.versesCount) {
        final verse = await widget.repository.getVerseByReference(
          surahId: currentSurah.id,
          ayahNumber: queryNumber,
        );
        if (verse != null) {
          addResult(_verseResult(verse, currentSurah));
        }
      }
    }

    if (queryNumbers.length >= 2) {
      final surahNumber = queryNumbers[0];
      final ayahNumber = queryNumbers[1];
      final surah = widget.repository.getSurahById(surahNumber);
      if (surah != null) {
        final verse = await widget.repository.getVerseByReference(
          surahId: surahNumber,
          ayahNumber: ayahNumber,
        );
        if (verse != null) {
          addResult(_verseResult(verse, surah));
        }
      }
    }

    final matchedSurahs = normalizedQuery.isEmpty
        ? const <Surah>[]
        : [
            for (final surah in widget.repository.getAllSurahs())
              if (_normalizeArabic(surah.name).contains(normalizedQuery)) surah,
          ];

    for (final surah in matchedSurahs.take(8)) {
      addResult(_surahResult(surah));
      if (queryNumbers.length == 1) {
        final ayahNumber = queryNumbers.first;
        if (ayahNumber >= 1 && ayahNumber <= surah.versesCount) {
          final verse = await widget.repository.getVerseByReference(
            surahId: surah.id,
            ayahNumber: ayahNumber,
          );
          if (verse != null) {
            addResult(_verseResult(verse, surah));
          }
        }
      }
    }

    final hasArabicText = RegExp(r'[\u0600-\u06FF]').hasMatch(cleanedQuery);
    if (hasArabicText && cleanedQuery.length >= 2) {
      final verses = await widget.repository.searchVerses(cleanedQuery);
      for (final verse in verses.take(12)) {
        final surah = widget.repository.getSurahById(verse.surahNumber);
        if (surah != null) {
          addResult(_verseResult(verse, surah));
        }
      }
    }

    return results.take(24).toList(growable: false);
  }

  _QuranSearchResult _pageResult(int pageNumber) {
    final pageInfo = pageInfoForPage(pageNumber);
    final surah = widget.repository.getSurahById(pageInfo.startSura);
    final page = ArabicNumberFormatter.format(pageNumber);
    return _QuranSearchResult(
      key: 'page:$pageNumber',
      title: 'الصفحة $page',
      subtitle: surah == null
          ? 'الانتقال إلى الصفحة'
          : 'تبدأ من سورة ${surah.name}',
      pageNumber: pageNumber,
    );
  }

  _QuranSearchResult _surahResult(Surah surah) {
    final pageNumber = pageNumberForVerse(sura: surah.id, aya: 1);
    final page = ArabicNumberFormatter.format(pageNumber);
    final verses = ArabicNumberFormatter.format(surah.versesCount);
    return _QuranSearchResult(
      key: 'surah:${surah.id}',
      title: 'سورة ${surah.name}',
      subtitle: '$verses آية • بداية الصفحة $page',
      pageNumber: pageNumber,
    );
  }

  _QuranSearchResult _verseResult(Verse verse, Surah surah) {
    final pageNumber = pageNumberForVerse(
      sura: verse.surahNumber,
      aya: verse.ayahNumber,
    );
    final ayahNumber = ArabicNumberFormatter.format(verse.ayahNumber);
    final page = ArabicNumberFormatter.format(pageNumber);
    return _QuranSearchResult(
      key: 'verse:${verse.surahNumber}:${verse.ayahNumber}',
      title: 'سورة ${surah.name} • الآية $ayahNumber',
      subtitle: '${verse.text} • الصفحة $page',
      pageNumber: pageNumber,
      verse: verse,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _controller,
                autofocus: true,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'ابحث باسم السورة أو رقم الصفحة أو نص الآية',
                  prefixIcon: const Icon(OctIcons.search),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _controller.clear();
                            _onQueryChanged('');
                          },
                        ),
                ),
                onChanged: (value) {
                  setState(() {});
                  _onQueryChanged(value);
                },
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_controller.text.trim().isNotEmpty && _results.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Text(
                    'لا توجد نتائج',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 440),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => Divider(
                      color: colorScheme.outlineVariant,
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          result.verse == null
                              ? OctIcons.book
                              : Icons.format_quote,
                          color: colorScheme.primary,
                        ),
                        title: Text(
                          result.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          result.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        onTap: () => Navigator.of(context).pop(result.target),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _cleanQuery(String value) {
    return value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^(سورة|صفحة|آية|ايه|اية)\s+'), '')
        .trim();
  }

  static String _normalizeArabic(String value) {
    return value
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .trim();
  }

  static int? _parseLocalizedInt(String value) {
    final normalized = _toEnglishDigits(value);
    return int.tryParse(normalized);
  }

  static List<int> _parseAllLocalizedInts(String value) {
    final normalized = _toEnglishDigits(value);
    final numbers = <int>[];

    for (final match in RegExp(r'\d+').allMatches(normalized)) {
      final number = int.tryParse(match.group(0)!);
      if (number != null) {
        numbers.add(number);
      }
    }

    return numbers;
  }

  static String _toEnglishDigits(String value) {
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    const persianDigits = '۰۱۲۳۴۵۶۷۸۹';
    final buffer = StringBuffer();

    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      final arabicIndex = arabicDigits.indexOf(char);
      final persianIndex = persianDigits.indexOf(char);
      if (arabicIndex >= 0) {
        buffer.write(arabicIndex);
      } else if (persianIndex >= 0) {
        buffer.write(persianIndex);
      } else {
        buffer.write(char);
      }
    }

    return buffer.toString();
  }
}
