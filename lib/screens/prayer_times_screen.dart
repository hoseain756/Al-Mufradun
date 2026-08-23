import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:provider/provider.dart';

import '../features/quran/presentation/utils/arabic_number_formatter.dart';
import '../providers/prayer_time_provider.dart';
import '../services/prayer_scheduler.dart';
import '../theme/app_icons.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  bool _isVisible = false;

  static const Map<String, IconData> _prayerIcons = {
    'fajr': OctIcons.sun,
    'dhuhr': OctIcons.sun,
    'asr': OctIcons.cloud,
    'maghrib': OctIcons.moon,
    'isha': OctIcons.moon,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isVisible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          title: Text(
            'مواقيت الصلاة',
            textAlign: TextAlign.start,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
        body: AnimatedOpacity(
          opacity: _isVisible ? 1 : 0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: Consumer<PrayerTimeProvider>(
            builder: (context, prayerProvider, _) {
              return SafeArea(
                child: RefreshIndicator(
                  onRefresh: prayerProvider.retry,
                  child: ListView(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      16,
                      12,
                      16,
                      24,
                    ),
                    children: [
                      _PrayerControlStrip(
                        allEnabled: prayerProvider.areAllPrayersEnabled,
                        onRefresh: prayerProvider.retry,
                        onToggleAll: prayerProvider.toggleAllPrayers,
                      ),
                      const SizedBox(height: 12),
                      if (prayerProvider.isLoading)
                        const _PrayerLoadingCard()
                      else if (prayerProvider.errorMessage != null)
                        _PrayerErrorCard(
                          message: prayerProvider.errorMessage!,
                          onRetry: prayerProvider.retry,
                        )
                      else ...[
                        _NextPrayerCard(provider: prayerProvider),
                        const SizedBox(height: 12),
                        _PrayerList(
                          provider: prayerProvider,
                          prayerIcons: _prayerIcons,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PrayerControlStrip extends StatelessWidget {
  final bool allEnabled;
  final Future<void> Function() onRefresh;
  final ValueChanged<bool> onToggleAll;

  const _PrayerControlStrip({
    required this.allEnabled,
    required this.onRefresh,
    required this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 8, 8),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            IconButton(
              tooltip: 'تحديث المواقيت',
              visualDensity: VisualDensity.compact,
              onPressed: onRefresh,
              icon: Icon(
                OctIcons.sync,
                size: 20,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'تنبيهات الصلوات',
                textAlign: TextAlign.start,
                style: textTheme.titleSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Switch(
              value: allEnabled,
              onChanged: onToggleAll,
            ),
          ],
        ),
      ),
    );
  }
}

class _NextPrayerCard extends StatefulWidget {
  final PrayerTimeProvider provider;

  const _NextPrayerCard({required this.provider});

  @override
  State<_NextPrayerCard> createState() => _NextPrayerCardState();
}

class _NextPrayerCardState extends State<_NextPrayerCard> {
  Timer? _timer;

  static const Map<String, IconData> _dynamicIcons = {
    'fajr': OctIcons.moon,
    'dhuhr': OctIcons.sun,
    'asr': OctIcons.sun,
    'maghrib': OctIcons.moon,
    'isha': OctIcons.moon,
  };

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Map<String, dynamic>? _calculateInterval(PrayerTimeProvider provider) {
    final now = DateTime.now();
    final nextKey = provider.nextPrayerKey;
    if (nextKey == null) return null;

    final fajr = provider.getPrayerTime('fajr');
    final dhuhr = provider.getPrayerTime('dhuhr');
    final asr = provider.getPrayerTime('asr');
    final maghrib = provider.getPrayerTime('maghrib');
    final isha = provider.getPrayerTime('isha');

    if (fajr == null || dhuhr == null || asr == null || maghrib == null || isha == null) {
      return null;
    }

    DateTime startTime;
    DateTime endTime;
    String prevName = '';
    String prevKey = '';

    switch (nextKey) {
      case 'fajr':
        if (fajr.isAfter(now)) {
          endTime = fajr;
          startTime = isha.subtract(const Duration(days: 1));
        } else {
          endTime = fajr.add(const Duration(days: 1));
          startTime = isha;
        }
        prevName = 'العشاء';
        prevKey = 'isha';
        break;
      case 'dhuhr':
        startTime = fajr;
        endTime = dhuhr;
        prevName = 'الفجر';
        prevKey = 'fajr';
        break;
      case 'asr':
        startTime = dhuhr;
        endTime = asr;
        prevName = 'الظهر';
        prevKey = 'dhuhr';
        break;
      case 'maghrib':
        startTime = asr;
        endTime = maghrib;
        prevName = 'العصر';
        prevKey = 'asr';
        break;
      case 'isha':
        startTime = maghrib;
        endTime = isha;
        prevName = 'المغرب';
        prevKey = 'maghrib';
        break;
      default:
        return null;
    }

    final totalDuration = endTime.difference(startTime).inSeconds;
    final elapsedDuration = now.difference(startTime).inSeconds;

    double progress = 0.0;
    if (totalDuration > 0) {
      progress = (elapsedDuration / totalDuration).clamp(0.0, 1.0);
    }

    const Map<String, int> iqamahIntervals = {
      'fajr': 20,
      'dhuhr': 20,
      'asr': 20,
      'maghrib': 10,
      'isha': 20,
    };

    final iqamahMinutes = iqamahIntervals[prevKey] ?? 20;
    final iqamahTime = startTime.add(Duration(minutes: iqamahMinutes));
    final isWaitingForIqamah = now.isBefore(iqamahTime);
    final iqamahRemainingMins = isWaitingForIqamah
        ? iqamahTime.difference(now).inMinutes + 1
        : 0;

    double iqamahProgress = 0.0;
    if (totalDuration > 0) {
      iqamahProgress = (iqamahTime.difference(startTime).inSeconds / totalDuration)
          .clamp(0.0, 0.98);
    }

    final nextIqamahMinutes = iqamahIntervals[nextKey] ?? 20;
    final nextIqamahTime = endTime.add(Duration(minutes: nextIqamahMinutes));

    return {
      'prevName': prevName,
      'prevKey': prevKey,
      'startTime': startTime,
      'endTime': endTime,
      'progress': progress,
      'iqamahTime': iqamahTime,
      'iqamahProgress': iqamahProgress,
      'isWaitingForIqamah': isWaitingForIqamah,
      'iqamahRemainingMins': iqamahRemainingMins,
      'nextIqamahTime': nextIqamahTime,
    };
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final isPm = hour >= 12;
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final period = isPm ? 'م' : 'ص';
    return '$h:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final nextKey = widget.provider.nextPrayerKey ?? 'fajr';
    final nextName = widget.provider.nextPrayerNameAr ?? 'الفجر';
    final nextIcon = _dynamicIcons[nextKey] ?? OctIcons.clock_fill;
    final formattedAdhanTime = widget.provider.getFormattedTime(nextKey) ?? '--:--';

    final gradientColors = isDark
        ? [
            scheme.primaryContainer,
            Color.alphaBlend(Colors.black.withValues(alpha: 0.22), scheme.primaryContainer),
          ]
        : [
            scheme.primary,
            Color.alphaBlend(Colors.black.withValues(alpha: 0.12), scheme.primary),
          ];

    final interval = _calculateInterval(widget.provider);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _PrayerCardBackgroundPainter(
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              nextIcon,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'الصلاة القادمة',
                              style: textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            OctIcons.clock_fill,
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'الأذان: $formattedAdhanTime',
                            style: textTheme.labelMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              nextName,
                              style: textTheme.displaySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_month_outlined,
                                    size: 13,
                                    color: Colors.white.withValues(alpha: 0.95),
                                  ),
                                  const SizedBox(width: 6),
                                  Builder(
                                    builder: (context) {
                                      HijriCalendar.setLocal('ar');
                                      final hijriDate = HijriCalendar.now();
                                      final hijriDayStr = ArabicNumberFormatter.format(hijriDate.hDay);
                                      final hijriYearStr = ArabicNumberFormatter.format(hijriDate.hYear);
                                      final hijriDateStr = '$hijriDayStr ${hijriDate.longMonthName} $hijriYearStr هـ';
                                      return Text(
                                        hijriDateStr,
                                        style: textTheme.labelSmall?.copyWith(
                                          color: Colors.white.withValues(alpha: 0.95),
                                          fontWeight: FontWeight.w600,
                                          height: 1.1,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _CountdownText(provider: widget.provider),
                    ],
                  ),
                  if (interval != null) ...[
                    const SizedBox(height: 18),
                    Divider(
                      color: Colors.white.withValues(alpha: 0.15),
                      height: 1,
                      thickness: 1,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 12,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: 4,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            left: 0,
                            right: 0,
                            child: FractionallySizedBox(
                              alignment: AlignmentDirectional.centerStart,
                              widthFactor: interval['progress'] as double,
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: FractionallySizedBox(
                              alignment: AlignmentDirectional.centerStart,
                              widthFactor: interval['iqamahProgress'] as double,
                              child: Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: Container(
                                  width: 2.5,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(
                                      alpha: (interval['isWaitingForIqamah'] as bool) ? 0.95 : 0.45,
                                    ),
                                    borderRadius: BorderRadius.circular(1.25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.25),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            left: 0,
                            right: 0,
                            child: FractionallySizedBox(
                              alignment: AlignmentDirectional.centerStart,
                              widthFactor: interval['progress'] as double,
                              child: Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.35),
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              interval['prevName'] as String,
                              style: textTheme.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.provider.getFormattedTime(interval['prevKey'] as String) ?? '',
                              style: textTheme.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _IqamahLabel(
                              iqamahTime: interval['iqamahTime'] as DateTime,
                              isWaiting: interval['isWaitingForIqamah'] as bool,
                              remainingMins: interval['iqamahRemainingMins'] as int,
                              textTheme: textTheme,
                              formatTime: _formatTime,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              nextName,
                              style: textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formattedAdhanTime,
                              style: textTheme.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'الإقامة: ${_formatTime(interval['nextIqamahTime'] as DateTime)}',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IqamahLabel extends StatelessWidget {
  final DateTime iqamahTime;
  final bool isWaiting;
  final int remainingMins;
  final TextTheme textTheme;
  final String Function(DateTime) formatTime;

  const _IqamahLabel({
    required this.iqamahTime,
    required this.isWaiting,
    required this.remainingMins,
    required this.textTheme,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = formatTime(iqamahTime);
    if (isWaiting) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Text(
          'الإقامة: $timeStr (باقٍ $remainingMins د)',
          style: textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      );
    }
    return Text(
      'الإقامة: $timeStr',
      style: textTheme.labelSmall?.copyWith(
        color: Colors.white.withValues(alpha: 0.4),
        fontSize: 10,
      ),
    );
  }
}

class _CountdownText extends StatefulWidget {
  final PrayerTimeProvider provider;

  const _CountdownText({required this.provider});

  @override
  State<_CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<_CountdownText> {
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

  @override
  void didUpdateWidget(covariant _CountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provider != widget.provider) {
      _updateRemaining();
    }
  }

  void _updateRemaining() {
    final duration = widget.provider.timeUntilNextPrayer;
    if (!mounted || duration == null) return;
    setState(() => _remaining = duration);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              _formatDuration(_remaining),
              style: textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'الوقت المتبقي',
            style: textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.65),
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerCardBackgroundPainter extends CustomPainter {
  final Color color;

  _PrayerCardBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width * 0.15, size.height * 0.6);

    canvas.drawCircle(center, 40, paint..color = color.withValues(alpha: 0.04));
    canvas.drawCircle(center, 70, paint..color = color.withValues(alpha: 0.03));
    canvas.drawCircle(center, 100, paint..color = color.withValues(alpha: 0.02));

    final path = Path()
      ..addArc(
        Rect.fromCircle(center: center, radius: 55),
        -0.5,
        3.14,
      );
    canvas.drawPath(path, paint..color = color.withValues(alpha: 0.04)..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant _PrayerCardBackgroundPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _PrayerList extends StatelessWidget {
  final PrayerTimeProvider provider;
  final Map<String, IconData> prayerIcons;

  const _PrayerList({
    required this.provider,
    required this.prayerIcons,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0;
              index < PrayerTimeProvider.prayers.length;
              index++)
            _PrayerRowWithDivider(
              prayer: PrayerTimeProvider.prayers[index],
              icon: prayerIcons[PrayerTimeProvider.prayers[index].key] ??
                  OctIcons.clock,
              formattedTime: provider.getFormattedTime(
                      PrayerTimeProvider.prayers[index].key) ??
                  '00:00',
              isEnabled:
                  provider.isEnabled(PrayerTimeProvider.prayers[index].key),
              isNext: provider.nextPrayerKey ==
                  PrayerTimeProvider.prayers[index].key,
              showDivider: index != PrayerTimeProvider.prayers.length - 1,
              onChanged: (enabled) => provider.togglePrayer(
                PrayerTimeProvider.prayers[index].key,
                enabled,
              ),
            ),
        ],
      ),
    );
  }
}

class _PrayerRowWithDivider extends StatelessWidget {
  final PrayerInfo prayer;
  final IconData icon;
  final String formattedTime;
  final bool isEnabled;
  final bool isNext;
  final bool showDivider;
  final ValueChanged<bool> onChanged;

  const _PrayerRowWithDivider({
    required this.prayer,
    required this.icon,
    required this.formattedTime,
    required this.isEnabled,
    required this.isNext,
    required this.showDivider,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Container(
          color: isNext ? scheme.secondaryContainer : null,
          padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 10, 10),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                icon,
                size: 22,
                color: isNext
                    ? scheme.onSecondaryContainer
                    : isEnabled
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  prayer.nameAr,
                  textAlign: TextAlign.start,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    color:
                        isNext ? scheme.onSecondaryContainer : scheme.onSurface,
                    fontWeight: isNext ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  formattedTime,
                  textAlign: TextAlign.right,
                  style: textTheme.labelLarge?.copyWith(
                    color: isNext
                        ? scheme.onSecondaryContainer
                        : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: isEnabled,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 14,
            endIndent: 14,
            color: scheme.outlineVariant,
          ),
      ],
    );
  }
}

class _PrayerLoadingCard extends StatelessWidget {
  const _PrayerLoadingCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 18,
          vertical: 28,
        ),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(
              'جارٍ حساب أوقات الصلاة...',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _PrayerErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(18),
        child: Column(
          children: [
            Icon(
              OctIcons.alert,
              color: scheme.primary,
              size: 30,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(OctIcons.sync, size: 18),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
