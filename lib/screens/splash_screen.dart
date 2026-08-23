import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart' show initializeAppServices;
import '../providers/app_provider.dart';
import '../providers/prayer_time_provider.dart';
import '../theme/app_icons.dart';
import 'main_navigation_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  /// Maximum time before we navigate regardless of data/services state.
  static const _maxSplashDuration = Duration(seconds: 5);

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    _initAndNavigate();
  }

  /// Sequential startup flow:
  /// 1. Initialise platform services (timezone, notifications, WorkManager).
  /// 2. Wait for adhkar data to finish loading in [AppProvider].
  /// 3. Start prayer-time fetching (safe — services are guaranteed ready).
  /// 4. Navigate to onboarding or main screen.
  Future<void> _initAndNavigate() async {
    final appProvider = context.read<AppProvider>();
    final prayerProvider = context.read<PrayerTimeProvider>();

    try {
      // ── Step 1: platform services ──────────────────────────
      await initializeAppServices();
    } catch (e) {
      debugPrint('❌ Services initialisation error: $e');
    }

    // ── Step 2: adhkar data ────────────────────────────────
    try {
      await appProvider.initialized.timeout(
        _maxSplashDuration,
        onTimeout: () {
          debugPrint('Splash timeout: adhkar data not ready yet.');
        },
      );
    } catch (_) {
      // Continue even if data timed out; home screen will show error state.
    }

    // ── Step 3: prayer times (fire-and-forget) ─────────────
    // Services are fully initialised at this point, so no race condition.
    prayerProvider.startFetching();

    // ── Step 4: navigate ───────────────────────────────────
    _navigate();
  }

  void _navigate() {
    if (_navigated || !mounted) return;
    _navigated = true;

    final appProvider = context.read<AppProvider>();
    final destination = appProvider.onboardingCompleted
        ? const MainNavigationScreen()
        : const OnboardingScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                OctIcons.book,
                size: 100,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'المفردون',
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
