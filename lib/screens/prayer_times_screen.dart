import 'dart:async';
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
                  final nextKey = prayerProvider.nextPrayerKey;

                  return Column(
                    children: [
                      // Next prayer countdown card
                      if (!prayerProvider.isLoading &&
                          prayerProvider.errorMessage == null &&
                          nextKey != null)
                        _NextPrayerCard(
                          prayerProvider: prayerProvider,
                          prayerIcons: _prayerIcons,
                        ),

                      // Main controls card
                      Card(
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
                                  fillColor:
                                      colorScheme.surfaceContainerHighest,
                                ),
                                items:
                                    PrayerScheduleRange.values.map((range) {
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

                              // Loading
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

                              // Error
                              if (!prayerProvider.isLoading &&
                                  prayerProvider.errorMessage != null)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
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
                                        onPressed: () =>
                                            prayerProvider.retry(),
                                        icon: const Icon(OctIcons.sync,
                                            size: 18),
                                        label: const Text('إعادة المحاولة'),
                                      ),
                                    ],
                                  ),
                                ),

                              // Prayer list
                              if (!prayerProvider.isLoading &&
                                  prayerProvider.errorMessage == null)
                                ...PrayerTimeProvider.prayers.map((prayer) {
                                  final isOn =
                                      prayerProvider.isEnabled(prayer.key);
                                  final formattedTime =
                                      prayerProvider.getFormattedTime(
                                              prayer.key) ??
                                          '0:00';
                                  final isNext = prayer.key == nextKey;

                                  return Column(
                                    children: [
                                      Container(
                                        decoration: isNext
                                            ? BoxDecoration(
                                                color: colorScheme
                                                    .primaryContainer
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              )
                                            : null,
                                        child: SwitchListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(prayer.nameAr),
                                          subtitle: Text(
                                            formattedTime,
                                            style:
                                                textTheme.bodySmall?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          secondary: Icon(
                                            _prayerIcons[prayer.key] ??
                                                OctIcons.clock,
                                            color: isOn
                                                ? colorScheme.primary
                                                : colorScheme
                                                    .onSurfaceVariant,
                                          ),
                                          value: isOn,
                                          onChanged: (enabled) async {
                                            await prayerProvider.togglePrayer(
                                              prayer.key,
                                              enabled,
                                            );
                                          },
                                        ),
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
                      ),
                    ],
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

// ── Next Prayer Countdown Card ───────────────────────────────
class _NextPrayerCard extends StatefulWidget {
  final PrayerTimeProvider prayerProvider;
  final Map<String, IconData> prayerIcons;

  const _NextPrayerCard({
    required this.prayerProvider,
    required this.prayerIcons,
  });

  @override
  State<_NextPrayerCard> createState() => _NextPrayerCardState();
}

class _NextPrayerCardState extends State<_NextPrayerCard> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final duration = widget.prayerProvider.timeUntilNextPrayer;
    if (duration != null) {
      setState(() => _remaining = duration);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final nextKey = widget.prayerProvider.nextPrayerKey;
    final nextName = widget.prayerProvider.nextPrayerNameAr;

    if (nextKey == null || nextName == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primaryContainer),
      ),
      child: Row(
        children: [
          Icon(
            widget.prayerIcons[nextKey] ?? OctIcons.clock,
            size: 32,
            color: colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الصلاة القادمة',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nextName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatDuration(_remaining),
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
