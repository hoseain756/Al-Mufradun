import 'package:adhkar_viewer/app/screens/splash_screen.dart';
import 'package:adhkar_viewer/core/app_settings_provider.dart';
import 'package:adhkar_viewer/features/adhkar/adhkar_provider.dart';
import 'package:adhkar_viewer/features/prayer_times/prayer_time_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/quran/presentation/screens/quran_index_screen.dart';

void main() {
  // Ensure Flutter bindings are ready
  WidgetsFlutterBinding.ensureInitialized();

  // runApp is called immediately so that SplashScreen renders on the very
  // first frame — no async work blocks the first paint.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
        ChangeNotifierProvider(create: (_) => AdhkarProvider()),
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
    return Consumer<AppSettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'Adhkar',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          // Fades native Liquid Glass views out while Flutter popup routes
          // (dialogs, bottom sheets) are above them, and restores them after.
          navigatorObservers: [LiquidGlassNavigatorObserver()],
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
