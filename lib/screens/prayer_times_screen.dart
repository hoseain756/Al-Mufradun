import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/prayer_time_provider.dart';
import '../theme/app_icons.dart';

class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({super.key});

  static const Map<String, IconData> _prayerIcons = {
    'fajr': OctIcons.sun,
    'dhuhr': OctIcons.sun,
    'asr': OctIcons.cloud,
    'maghrib': OctIcons.moon,
    'isha': OctIcons.moon,
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            centerTitle: false,
            title: Text('مواقيت الصلاة'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: Consumer<PrayerTimeProvider>(
                builder: (context, prayerProvider, _) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'المدة: ${prayerProvider.scheduleRange.labelAr}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(OctIcons.sync, size: 20),
                                onPressed: () => prayerProvider.retry(),
                              ),
                              Switch(
                                value: prayerProvider.areAllPrayersEnabled,
                                onChanged: (enabled) {
                                  prayerProvider.toggleAllPrayers(enabled);
                                },
                              ),
                            ],
                          ),
                          DropdownButtonFormField<PrayerScheduleRange>(
                            initialValue: prayerProvider.scheduleRange,
                            decoration: InputDecoration(
                              labelText: 'مدة جدولة التنبيهات',
                              prefixIcon: const Icon(OctIcons.clock),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest,
                            ),
                            items: PrayerScheduleRange.values.map((range) {
                              return DropdownMenuItem(
                                value: range,
                                child: Text(range.labelAr),
                              );
                            }).toList(),
                            onChanged: (range) {
                              if (range != null) {
                                prayerProvider.setScheduleRange(range);
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          if (prayerProvider.isLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 28),
                              child: Center(
                                child: Column(
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text('جارٍ حساب أوقات الصلاة...'),
                                  ],
                                ),
                              ),
                            ),
                          if (!prayerProvider.isLoading &&
                              prayerProvider.errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                children: [
                                  Icon(
                                    OctIcons.alert,
                                    color: colorScheme.error,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    prayerProvider.errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.error,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton.tonalIcon(
                                    onPressed: () => prayerProvider.retry(),
                                    icon:
                                        const Icon(OctIcons.sync, size: 18),
                                    label: const Text('إعادة المحاولة'),
                                  ),
                                ],
                              ),
                            ),
                          if (!prayerProvider.isLoading &&
                              prayerProvider.errorMessage == null)
                            ...PrayerTimeProvider.prayers.map((prayer) {
                              final isOn = prayerProvider.isEnabled(prayer.key);
                              final formattedTime =
                                  prayerProvider.getFormattedTime(prayer.key) ??
                                      '0:00';
                              return Column(
                                children: [
                                  SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(prayer.nameAr),
                                    subtitle: Text(
                                      formattedTime,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    secondary: Icon(
                                      _prayerIcons[prayer.key] ??
                                          OctIcons.clock,
                                      color: isOn
                                          ? colorScheme.primary
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                    value: isOn,
                                    onChanged: (enabled) async {
                                      await prayerProvider.togglePrayer(
                                        prayer.key,
                                        enabled,
                                      );
                                    },
                                  ),
                                  if (prayer.key != 'isha')
                                    Divider(
                                      height: 1,
                                      indent: 56,
                                      color: colorScheme.outlineVariant
                                          .withValues(alpha: 0.5),
                                    ),
                                ],
                              );
                            }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
