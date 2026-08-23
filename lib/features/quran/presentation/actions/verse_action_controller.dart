import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../theme/app_icons.dart';
import '../../data/static/mushaf_page_mapping.dart';
import '../utils/quran_bookmark_store.dart';
import '../utils/quran_page_font_loader.dart';
import '../utils/verse_action_formatter.dart';
import '../widgets/verse_share_card_widget.dart';
import 'verse_action_models.dart';

typedef VerseActionPredicate = bool Function(VerseActionContext context);
typedef VerseCopyHandler = Future<void> Function(
  BuildContext parentContext,
  BuildContext sheetContext,
  VerseActionContext actionContext,
);
typedef VerseTextShareHandler = Future<void> Function(
  BuildContext parentContext,
  BuildContext sheetContext,
  VerseActionContext actionContext,
);
typedef VerseImageShareHandler = Future<void> Function(
  BuildContext parentContext,
  BuildContext sheetContext,
  VerseActionContext actionContext,
);

class VerseActionController {
  VerseActionController({
    List<VerseActionDefinition>? definitions,
    VerseActionTracker? tracker,
    VerseCopyHandler? copyHandler,
    VerseTextShareHandler? textShareHandler,
    VerseImageShareHandler? imageShareHandler,
  })  : _definitions = definitions ?? defaultDefinitions,
        _tracker = tracker,
        _copyHandler = copyHandler,
        _textShareHandler = textShareHandler,
        _imageShareHandler = imageShareHandler;

  final List<VerseActionDefinition> _definitions;
  final VerseActionTracker? _tracker;
  final VerseCopyHandler? _copyHandler;
  final VerseTextShareHandler? _textShareHandler;
  final VerseImageShareHandler? _imageShareHandler;

  static final List<VerseActionDefinition> defaultDefinitions = [
    VerseActionDefinition(
      type: VerseActionType.bookmark,
      label: 'حفظ الآية والموضع',
      icon: OctIcons.star,
      order: 5,
      analyticsName: 'quran_verse_bookmark',
      visibleWhen: _isStartVerseNotBookmarked,
    ),
    VerseActionDefinition(
      type: VerseActionType.removeBookmark,
      label: 'إزالة الآية من المحفوظات',
      icon: Icons.star_border_rounded,
      order: 6,
      analyticsName: 'quran_verse_remove_bookmark',
      visibleWhen: _isStartVerseBookmarked,
    ),
    const VerseActionDefinition(
      type: VerseActionType.copy,
      label: 'نسخ الآية',
      icon: OctIcons.copy,
      order: 10,
      analyticsName: 'quran_verse_copy',
    ),
    const VerseActionDefinition(
      type: VerseActionType.shareText,
      label: 'مشاركة نصية',
      icon: OctIcons.share,
      order: 20,
      analyticsName: 'quran_verse_share_text',
    ),
    const VerseActionDefinition(
      type: VerseActionType.shareImage,
      label: 'مشاركة كصورة',
      icon: Icons.image_outlined,
      order: 30,
      analyticsName: 'quran_verse_share_image',
    ),
  ];

  List<VerseActionCommand> actionsFor(VerseActionContext context) {
    final commands = _definitions
        .where((definition) => definition.isVisible(context))
        .map((definition) => definition.toCommand(context))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return List.unmodifiable(commands);
  }

  Future<void> execute({
    required BuildContext parentContext,
    required BuildContext sheetContext,
    required VerseActionContext actionContext,
    required VerseActionCommand command,
  }) async {
    if (!command.isEnabled) return;

    _track(command, actionContext);

    switch (command.type) {
      case VerseActionType.copy:
        await (_copyHandler ?? _copyVerse)(
          parentContext,
          sheetContext,
          actionContext,
        );
        break;
      case VerseActionType.shareText:
        await (_textShareHandler ?? _shareVerseText)(
          parentContext,
          sheetContext,
          actionContext,
        );
        break;
      case VerseActionType.shareImage:
        await (_imageShareHandler ?? _shareVerseImage)(
          parentContext,
          sheetContext,
          actionContext,
        );
        break;
      case VerseActionType.bookmark:
        await _bookmarkVerse(parentContext, sheetContext, actionContext);
        break;
      case VerseActionType.removeBookmark:
        await _removeBookmark(parentContext, sheetContext, actionContext);
        break;
      case VerseActionType.tafsir:
      case VerseActionType.notes:
      case VerseActionType.highlight:
        throw UnsupportedError(
          'Verse action is not implemented: ${command.type}',
        );
    }
  }

  Future<void> _bookmarkVerse(
    BuildContext parentContext,
    BuildContext sheetContext,
    VerseActionContext actionContext,
  ) async {
    await QuranBookmarkStore.saveVerse(actionContext.startVerse);

    if (sheetContext.mounted) {
      Navigator.of(sheetContext).pop();
    }

    if (!parentContext.mounted) return;
    ScaffoldMessenger.of(parentContext)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('تم حفظ الآية وموضع التوقف')),
      );
  }

  Future<void> _removeBookmark(
    BuildContext parentContext,
    BuildContext sheetContext,
    VerseActionContext actionContext,
  ) async {
    final didRemove =
        await QuranBookmarkStore.removeVerse(actionContext.startVerse);

    if (sheetContext.mounted) {
      Navigator.of(sheetContext).pop();
    }

    if (!parentContext.mounted) return;
    ScaffoldMessenger.of(parentContext)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            didRemove
                ? 'تمت إزالة الآية من المحفوظات'
                : 'هذه الآية غير محفوظة',
          ),
        ),
      );
  }

  Future<void> _copyVerse(
    BuildContext parentContext,
    BuildContext sheetContext,
    VerseActionContext actionContext,
  ) async {
    final text = VerseActionFormatter.formatForCopy(
      context: actionContext,
    );

    await Clipboard.setData(ClipboardData(text: text));

    if (sheetContext.mounted) {
      Navigator.of(sheetContext).pop();
    }

    if (!parentContext.mounted) return;
    ScaffoldMessenger.of(parentContext)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            actionContext.isRange ? 'تم نسخ النطاق المحدد' : 'تم نسخ الآية',
          ),
        ),
      );
  }

  Future<void> _shareVerseText(
    BuildContext parentContext,
    BuildContext sheetContext,
    VerseActionContext actionContext,
  ) async {
    final text = VerseActionFormatter.formatForTextShare(
      context: actionContext,
    );

    if (sheetContext.mounted) {
      Navigator.of(sheetContext).pop();
    }

    await Share.share(
      text,
      sharePositionOrigin: _shareOriginFor(parentContext),
    );
  }

  Rect? _shareOriginFor(BuildContext context) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;

    final topLeft = renderObject.localToGlobal(Offset.zero);
    return topLeft & renderObject.size;
  }

  Future<void> _shareVerseImage(
    BuildContext parentContext,
    BuildContext sheetContext,
    VerseActionContext actionContext,
  ) async {
    if (sheetContext.mounted) {
      Navigator.of(sheetContext).pop();
    }

    await _loadShareImageFonts(actionContext);

    final overlay = Overlay.maybeOf(parentContext, rootOverlay: true);
    if (overlay == null) return;

    final boundaryKey = GlobalKey();
    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: -10000,
          top: -10000,
          child: Material(
            type: MaterialType.transparency,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: RepaintBoundary(
                key: boundaryKey,
                child: VerseShareCardWidget(
                  actionContext: actionContext,
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);

    try {
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 16));
      if (!parentContext.mounted) return;

      final boundaryContext = boundaryKey.currentContext;
      if (boundaryContext == null) {
        _showError(parentContext, 'تعذر إنشاء صورة المشاركة');
        return;
      }

      final renderObject = boundaryContext.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        _showError(parentContext, 'تعذر إنشاء صورة المشاركة');
        return;
      }

      final image = await renderObject.toImage(
        pixelRatio: ui.PlatformDispatcher.instance.views.isEmpty
            ? 3.0
            : ui.PlatformDispatcher.instance.views.first.devicePixelRatio,
      );

      final pngBytes = await _imageToPng(image);
      final xFile = await _writeTempPng(
        bytes: pngBytes,
        surahId: actionContext.startSurah.id,
        startAyahNumber: actionContext.startVerse.ayahNumber,
        endSurahId: actionContext.endSurah.id,
        endAyahNumber: actionContext.endVerse.ayahNumber,
      );
      if (!parentContext.mounted) return;

      await Share.shareXFiles(
        [xFile],
        text: VerseActionFormatter.formatForTextShare(
          context: actionContext,
        ),
        sharePositionOrigin: _shareOriginFor(parentContext),
      );
    } catch (_) {
      if (parentContext.mounted) {
        _showError(parentContext, 'تعذر مشاركة الصورة');
      }
    } finally {
      entry.remove();
    }
  }

  Future<void> _loadShareImageFonts(VerseActionContext actionContext) async {
    final pageNumbers = actionContext.verses
        .map(
          (verse) => pageNumberForVerse(
            sura: verse.surahNumber,
            aya: verse.ayahNumber,
          ),
        )
        .toSet();

    await Future.wait(pageNumbers.map(QuranPageFontLoader.loadPageFont));
  }

  Future<Uint8List> _imageToPng(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      throw StateError('Failed to encode image as PNG');
    }
    return data.buffer.asUint8List();
  }

  Future<XFile> _writeTempPng({
    required Uint8List bytes,
    required int surahId,
    required int startAyahNumber,
    required int endSurahId,
    required int endAyahNumber,
  }) async {
    final dir = await getTemporaryDirectory();
    final filename =
        'quran_${surahId}_$startAyahNumber-$endSurahId-$endAyahNumber.png';
    final path = p.join(dir.path, filename);
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return XFile(path);
  }

  void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _track(VerseActionCommand command, VerseActionContext context) {
    _tracker?.call(
      VerseActionAnalyticsEvent(
        type: command.type,
        analyticsName: command.analyticsName,
        surahId: context.startSurah.id,
        ayahNumber: context.startVerse.ayahNumber,
        verseId: context.startVerse.id,
      ),
    );
  }
}

class VerseActionDefinition {
  const VerseActionDefinition({
    required this.type,
    required this.label,
    required this.icon,
    required this.order,
    required this.analyticsName,
    this.visibleWhen = _alwaysTrue,
    this.enabledWhen = _alwaysTrue,
    this.disabledReason,
  });

  final VerseActionType type;
  final String label;
  final IconData icon;
  final int order;
  final String analyticsName;
  final VerseActionPredicate visibleWhen;
  final VerseActionPredicate enabledWhen;
  final String? disabledReason;

  bool isVisible(VerseActionContext context) => visibleWhen(context);

  VerseActionCommand toCommand(VerseActionContext context) {
    final enabled = enabledWhen(context);
    return VerseActionCommand(
      type: type,
      label: label,
      icon: icon,
      order: order,
      analyticsName: analyticsName,
      isEnabled: enabled,
      disabledReason: enabled ? null : disabledReason,
    );
  }

  static bool _alwaysTrue(VerseActionContext context) => true;
}

bool _isStartVerseBookmarked(VerseActionContext context) {
  return context.isStartVerseBookmarked;
}

bool _isStartVerseNotBookmarked(VerseActionContext context) {
  return !context.isStartVerseBookmarked;
}
