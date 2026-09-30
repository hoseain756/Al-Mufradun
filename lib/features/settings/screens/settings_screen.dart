import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_settings_provider.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../adhkar/adhkar_provider.dart';
import '../widgets/rate_app_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettingsProvider>(context);
    final adhkar = Provider.of<AdhkarProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            centerTitle: false,
            title: Text('الإعدادات'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Font Size with Slider + Preview ──────────
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'حجم الخط',
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              settings.fontSize.toStringAsFixed(0),
                              style: textTheme.labelLarge?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Slider(
                          value: settings.fontSize,
                          min: 14.0,
                          max: 32.0,
                          divisions: 9,
                          label: settings.fontSize.toStringAsFixed(0),
                          onChanged: (value) {
                            settings.adjustFontSize(value - settings.fontSize);
                          },
                        ),
                        const SizedBox(height: 16),
                        // Live preview
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'معاينة',
                                style: textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                                style: AppTheme.zekrStyle(
                                  isQuranicFont: false,
                                  fontSize: settings.fontSize,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Theme Mode SegmentedButton ───────────────
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              settings.themeMode == ThemeMode.dark
                                  ? OctIcons.moon
                                  : settings.themeMode == ThemeMode.light
                                      ? OctIcons.sun
                                      : OctIcons.gear,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'المظهر',
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<ThemeMode>(
                            segments: const [
                              ButtonSegment(
                                value: ThemeMode.system,
                                label: Text('تلقائي'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.light,
                                label: Text('فاتح'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                label: Text('داكن'),
                              ),
                            ],
                            selected: {settings.themeMode},
                            onSelectionChanged: (selected) {
                              settings.setThemeMode(selected.first);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Reset Dhikr Counters ─────────────────────
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: Icon(OctIcons.sync,
                        color: colorScheme.onSurfaceVariant),
                    title: Text(
                      'إعادة تعيين العدادات',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'إعادة تعيين جميع عدادات الأذكار',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Icon(OctIcons.arrow_right,
                        size: 18, color: colorScheme.onSurfaceVariant),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('إعادة تعيين العدادات'),
                          content: const Text(
                            'هل أنت متأكد من إعادة تعيين جميع عدادات الأذكار؟',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('إلغاء'),
                            ),
                            FilledButton(
                              onPressed: () {
                                adhkar.resetAllDhikrCounts();
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم إعادة تعيين جميع العدادات'),
                                  ),
                                );
                              },
                              child: const Text('إعادة تعيين'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const RateAppCard(),

                // ── About ────────────────────────────────────
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: Icon(OctIcons.info,
                        color: colorScheme.onSurfaceVariant),
                    title: Text(
                      'عن التطبيق',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'الإصدار 1.0.0',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          icon: Icon(
                            OctIcons.book,
                            size: 48,
                            color: colorScheme.primary,
                          ),
                          title: const Text('المفردون'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'الإصدار 1.0.0',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'تطبيق الأذكار والأدعية اليومية',
                                style: textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('إغلاق'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
