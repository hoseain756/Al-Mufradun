import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_icons.dart';
import 'main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  /// Minimum time the splash must remain visible (for branding).
  static const _minSplashDuration = Duration(seconds: 1);

  /// Maximum time before we navigate regardless of data state.
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

    _awaitDataAndNavigate();
  }

  Future<void> _awaitDataAndNavigate() async {
    final appProvider = context.read<AppProvider>();

    // Wait for at least minSplash AND data to be ready, but no longer than maxSplash.
    final minSplash = Future.delayed(_minSplashDuration);
    final dataReady = appProvider.initialized;

    // Wait for both the minimum duration and data to be ready
    await Future.wait([minSplash, dataReady]).timeout(
      _maxSplashDuration,
      onTimeout: () {
        // Timed out — navigate anyway (will show error state in UI)
        debugPrint('Splash timeout reached; navigating without data.');
        return [null, null];
      },
    );

    _navigate();
  }

  void _navigate() {
    if (_navigated || !mounted) return;
    _navigated = true;

    final appProvider = context.read<AppProvider>();
    final destination = appProvider.onboardingCompleted
        ? const MainNavigationScreen()
        : const MainNavigationScreen(); // Replace with OnboardingScreen when built

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
