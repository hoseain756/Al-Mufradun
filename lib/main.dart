import 'dart:ui';

import 'package:adhkar_viewer/features/quran/presentation/screens/quran_index_screen.dart';
import 'package:adhkar_viewer/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/services.dart';

import 'providers/app_provider.dart';
import 'providers/prayer_time_provider.dart';
import 'services/notification_service.dart';
import 'services/prayer_scheduler.dart';
import 'services/timezone_service.dart';
import 'theme/app_theme.dart';

const String prayerRefreshTaskName = 'refreshPrayerSchedule';
const String prayerRefreshUniqueName = 'com.hussein.almufradun.prayer.refresh';

@pragma('vm:entry-point')
void prayerRefreshCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    await TimezoneService.configureLocalTimeZone();
    await NotificationService.instance.init();

    PrayerScheduler.instance.attachMethodChannelHandler();
    await PrayerScheduler.instance.refreshSchedule(requestPermissions: false);

    return true;
  });
}

Future<void> _configurePrayerBackgroundRefresh() async {
  await Workmanager().initialize(prayerRefreshCallbackDispatcher);
  await Workmanager().registerPeriodicTask(
    prayerRefreshUniqueName,
    prayerRefreshTaskName,
    frequency: const Duration(hours: 12),
    initialDelay: const Duration(minutes: 15),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
  );
}

/// Initialise timezone, notifications, method-channel bridges and WorkManager.
///
/// Called once by [SplashScreen] after it is already visible on-screen,
/// guaranteeing no race between services and consumers like
/// [PrayerTimeProvider].
Future<void> initializeAppServices() async {
  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure local timezone correctly before anything that needs tz.local.
  await TimezoneService.configureLocalTimeZone();

  // Initialize the notification service singleton
  await NotificationService.instance.init();
  PrayerScheduler.instance.attachMethodChannelHandler();

  // Keep prayer notification schedules refreshed while the app is closed.
  await _configurePrayerBackgroundRefresh();
}

void main() {
  // Ensure Flutter bindings are ready
  WidgetsFlutterBinding.ensureInitialized();

  // runApp is called immediately so that SplashScreen renders on the very
  // first frame — no async work blocks the first paint.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        // PrayerTimeProvider does NOT auto-initialise; SplashScreen triggers
        // it after services (timezone, notifications) are fully ready.
        ChangeNotifierProvider(
          create: (_) => PrayerTimeProvider(autoInitialize: false),
        ),
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
          routes: {
            QuranIndexScreen.routeName: (_) => QuranIndexScreen(),
          },
        );
      },
    );
  }
}
