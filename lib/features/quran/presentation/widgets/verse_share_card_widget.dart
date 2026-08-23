import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../data/static/mushaf_page_mapping.dart';
import '../../domain/entities/verse.dart';
import '../actions/verse_action_models.dart';
import '../utils/arabic_number_formatter.dart';
import '../utils/verse_action_formatter.dart';

class VerseShareCardWidget extends StatelessWidget {
  const VerseShareCardWidget({
    super.key,
    required this.actionContext,
  });

  final VerseActionContext actionContext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final groups = _buildPageGroups(actionContext.verses);
    final pageLabel = _formatPageLabel(groups);

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 720,
        maxWidth: 720,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final group in groups) ...[
                _QcfShareExcerpt(group: group),
                if (group != groups.last) const SizedBox(height: 18),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: Divider(color: colorScheme.outlineVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      pageLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: colorScheme.outlineVariant)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'المفردون • '
                '${VerseActionFormatter.formatSelectionSummary(actionContext)}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static List<_SharePageGroup> _buildPageGroups(List<Verse> verses) {
    final groups = <_SharePageGroup>[];
    for (final verse in verses) {
      final pageNumber = pageNumberForVerse(
        sura: verse.surahNumber,
        aya: verse.ayahNumber,
      );
      if (groups.isNotEmpty && groups.last.pageNumber == pageNumber) {
        groups.last.verses.add(verse);
      } else {
        groups.add(_SharePageGroup(pageNumber: pageNumber, verses: [verse]));
      }
    }
    return groups;
  }

  static String _formatPageLabel(List<_SharePageGroup> groups) {
    final firstPage = groups.first.pageNumber;
    final lastPage = groups.last.pageNumber;

    if (firstPage == lastPage) {
      return 'صفحة ${ArabicNumberFormatter.format(firstPage)}';
    }

    return 'صفحات ${ArabicNumberFormatter.format(firstPage)} - '
        '${ArabicNumberFormatter.format(lastPage)}';
  }
}

class _SharePageGroup {
  _SharePageGroup({
    required this.pageNumber,
    required this.verses,
  });

  final int pageNumber;
  final List<Verse> verses;
}

class _QcfShareExcerpt extends StatelessWidget {
  const _QcfShareExcerpt({required this.group});

  final _SharePageGroup group;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pageFont = AppTheme.getQuranPageFont(group.pageNumber);

    return Text.rich(
      TextSpan(
        text: _formatQcfText(group.verses),
      ),
      style: TextStyle(
        fontFamily: pageFont,
        fontSize: 44,
        height: 1.55,
        color: colorScheme.onSurface,
      ),
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
    );
  }

  static String _formatQcfText(List<Verse> verses) {
    return [
      for (final verse in verses) verse.qcfText.trim(),
    ].join(' ');
  }
}
