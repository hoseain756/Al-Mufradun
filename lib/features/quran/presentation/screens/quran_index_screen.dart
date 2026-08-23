import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../theme/app_icons.dart';
import '../../../../theme/app_theme.dart';
import '../../data/quran_repository_factory.dart';
import '../../data/static/mushaf_page_mapping.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/quran_repository.dart';
import '../utils/arabic_number_formatter.dart';
import 'surah_reader_screen.dart';

class QuranIndexScreen extends StatelessWidget {
  QuranIndexScreen({
    super.key,
    QuranRepository? repository,
  }) : _repository = repository ?? createQuranRepository();

  static const String routeName = '/quran';

  final QuranRepository _repository;

  @override
  Widget build(BuildContext context) {
    final surahs = _repository.getAllSurahs();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: surahs.isEmpty
            ? const Center(child: Text('لا توجد سور متاحة'))
            : CustomScrollView(
                slivers: [
                  const SliverAppBar(
                    pinned: true,
                    centerTitle: false,
                    title: Text('القرآن الكريم'),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: _QuranIndexHeader(totalSurahs: surahs.length),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final surah = surahs[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: _SurahListTile(
                              surah: surah,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _openSurah(context, surah);
                              },
                            ),
                          );
                        },
                        childCount: surahs.length,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _openSurah(BuildContext context, Surah surah) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SurahReaderScreen(
          surah: surah,
          repository: _repository,
        ),
      ),
    );
  }
}

class _QuranIndexHeader extends StatelessWidget {
  const _QuranIndexHeader({required this.totalSurahs});

  final int totalSurahs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Stack(
          children: [
            // Decorative background icon
            Positioned(
              left: -20,
              bottom: -20,
              child: Icon(
                OctIcons.book,
                size: 140,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          OctIcons.book,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'فهرس السور',
                              style: textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontFamily: AppTheme.handicraftsFont,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Text(
                          '${ArabicNumberFormatter.format(totalSurahs)} سورة',
                          style: textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Text(
                          '${ArabicNumberFormatter.format(604)} صفحة',
                          style: textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahListTile extends StatelessWidget {
  const _SurahListTile({
    required this.surah,
    required this.onTap,
  });

  final Surah surah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final startPage = pageNumberForVerse(sura: surah.id, aya: 1);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _RubElHizbBadge(number: surah.id),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.name,
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontFamily: AppTheme.handicraftsFont,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'آياتها: ${ArabicNumberFormatter.format(surah.versesCount)} • بداية الصفحة: ${ArabicNumberFormatter.format(startPage)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right, // Under RTL this points left (direction of navigation deeper)
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RubElHizbBadge extends StatelessWidget {
  final int number;
  const _RubElHizbBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer rotated square (45 degrees)
          Transform.rotate(
            angle: 0.785398, // 45 degrees in radians
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Inner standard square
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.4),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Center number text
          Text(
            ArabicNumberFormatter.format(number),
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
