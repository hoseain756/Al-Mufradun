import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';
import 'package:provider/provider.dart';
import '../../../core/app_settings_provider.dart';
import '../../../core/native/liquid_glass.dart';
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
                        useNativeIOSSystemUI
                            ? LiquidGlassSlider(
                                value: settings.fontSize,
                                min: 14.0,
                                max: 32.0,
                                step: 2.0,
                                onChanged: (value) {
                                  settings.adjustFontSize(
                                    value - settings.fontSize,
                                  );
                                },
                              )
                            : Slider(
                                value: settings.fontSize,
                                min: 14.0,
                                max: 32.0,
                                divisions: 9,
                                label: settings.fontSize.toStringAsFixed(0),
                                onChanged: (value) {
                                  settings.adjustFontSize(
                                    value - settings.fontSize,
                                  );
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
                          child: useNativeIOSSystemUI
                              ? LiquidGlassSegmentedControl(
                                  labels: const ['تلقائي', 'فاتح', 'داكن'],
                                  selectedIndex: switch (settings.themeMode) {
                                    ThemeMode.system => 0,
                                    ThemeMode.light => 1,
                                    ThemeMode.dark => 2,
                                  },
                                  onValueChanged: (i) {
                                    settings.setThemeMode(
                                      switch (i) {
                                        0 => ThemeMode.system,
                                        1 => ThemeMode.light,
                                        _ => ThemeMode.dark,
                                      },
                                    );
                                  },
                                )
                              : SegmentedButton<ThemeMode>(
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
                    onTap: () async {
                      final result = await showAdaptiveAlert(
                        context: context,
                        title: 'إعادة تعيين العدادات',
                        message:
                            'هل أنت متأكد من إعادة تعيين جميع عدادات الأذكار؟',
                        actions: const [
                          AdaptiveAlertAction(
                            id: 'reset',
                            title: 'إعادة تعيين',
                            isDestructive: true,
                          ),
                          AdaptiveAlertAction(
                            id: 'cancel',
                            title: 'إلغاء',
                            isCancel: true,
                          ),
                        ],
                      );
                      if (result == 'reset') {
                        adhkar.resetAllDhikrCounts();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم إعادة تعيين جميع العدادات'),
                          ),
                        );
                      }
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
                      showAdaptiveAlert(
                        context: context,
                        title: 'المفردون — الإصدار 1.0.0',
                        message: 'تطبيق الأذكار والأدعية اليومية',
                        actions: const [
                          AdaptiveAlertAction(id: 'close', title: 'إغلاق'),
                        ],
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
