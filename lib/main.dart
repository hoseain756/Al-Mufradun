import 'dart:ui';

import 'package:adhkar_viewer/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';
import 'package:flutter/services.dart';

import 'providers/app_provider.dart';
import 'providers/prayer_time_provider.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

const String prayerRefreshTaskName = 'refreshPrayerSchedule';
const String prayerRefreshUniqueName = 'almufradun_prayer_refresh';

Future<void> _configureLocalTimeZone() async {
  // Initialize timezone database
  tz.initializeTimeZones();

  try {
    // Detect device timezone ID
    final rawTimezone = await FlutterTimezone.getLocalTimezone();
    String timezoneId = rawTimezone.toString();

    // Extract ID if it's in the "TimezoneInfo(ID, ...)" format
    if (timezoneId.contains('(') && timezoneId.contains(',')) {
      timezoneId = timezoneId
          .substring(timezoneId.indexOf('(') + 1, timezoneId.indexOf(','))
          .trim();
    } else if (timezoneId.contains('(') && timezoneId.contains(')')) {
      timezoneId = timezoneId
          .substring(timezoneId.indexOf('(') + 1, timezoneId.indexOf(')'))
          .trim();
    }

    // Set local location for the timezone package
    tz.setLocalLocation(tz.getLocation(timezoneId));
    debugPrint('🌍 Timezone configured: $timezoneId');
  } catch (e) {
    debugPrint('❌ Error configuring timezone: $e');
    // Fallback to UTC if detection fails to prevent crash
    tz.setLocalLocation(tz.getLocation('UTC'));
  }
}

@pragma('vm:entry-point')
void prayerRefreshCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    await _configureLocalTimeZone();
    await NotificationService.instance.init();

    final prayerProvider = PrayerTimeProvider(autoInitialize: false);
    await prayerProvider.refreshPrayerScheduleInBackground();

    return true;
  });
}

Future<void> _configurePrayerBackgroundRefresh() async {
  await Workmanager().initialize(prayerRefreshCallbackDispatcher);
  await Workmanager().registerPeriodicTask(
    prayerRefreshUniqueName,
    prayerRefreshTaskName,
    frequency: const Duration(hours: 24),
    initialDelay: const Duration(minutes: 15),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
  );
}

void main() async {
  // Ensure Flutter bindings are ready before async initialization
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure local timezone correctly before running the app
  await _configureLocalTimeZone();

  // Initialize the notification service singleton
  await NotificationService.instance.init();

  // Keep prayer notification schedules refreshed while the app is closed.
  await _configurePrayerBackgroundRefresh();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        // PrayerTimeProvider auto-fetches location & calculates times on creation
        ChangeNotifierProvider(create: (_) => PrayerTimeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: 'Adhkar',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: provider.themeMode,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // Dismiss keyboard / unfocus on tap outside any input field
          builder: (context, child) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: child,
            );
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}
