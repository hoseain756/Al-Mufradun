import 'dart:async';

import 'package:flutter/services.dart';

import '../../../../theme/app_theme.dart';
import '../../data/static/mushaf_page_mapping.dart';

class QuranPageFontLoader {
  QuranPageFontLoader._();

  static final Map<int, Future<void>> _loadedFonts = {};

  static Future<void> loadPageFont(int pageNumber) {
    RangeError.checkValueInInterval(
      pageNumber,
      1,
      kMushafPageCount,
      'pageNumber',
    );

    return _loadedFonts.putIfAbsent(pageNumber, () async {
      final pageStr = pageNumber.toString().padLeft(3, '0');
      final loader = FontLoader(AppTheme.getQuranPageFont(pageNumber))
        ..addFont(
          rootBundle.load('assets/fonts/QCF2BSMLfonts/QCF2$pageStr.ttf'),
        );
      await loader.load();
    });
  }

  /// Preload fonts for pages around [centerPage] within [range].
  /// Example: preloadRange(page=10, range=5) loads pages 5…15.
  /// This is a fire-and-forget operation; pages already cached are skipped.
  static void preloadRange(int centerPage, {int range = 5}) {
    final first = (centerPage - range).clamp(1, kMushafPageCount);
    final last = (centerPage + range).clamp(1, kMushafPageCount);
    for (var p = first; p <= last; p++) {
      if (!_loadedFonts.containsKey(p)) {
        unawaited(loadPageFont(p));
      }
    }
  }
}
