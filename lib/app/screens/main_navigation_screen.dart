import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';
import 'package:provider/provider.dart';
import '../../core/native/liquid_glass.dart';
import '../../features/quran/presentation/screens/quran_index_screen.dart';
import '../../features/adhkar/adhkar_provider.dart';
import '../../core/theme/app_icons.dart';

import '../../features/adhkar/screens/favorites_screen.dart';
import '../../features/adhkar/screens/home_screen.dart';
import '../../features/prayer_times/screens/prayer_times_screen.dart';
import '../../features/qibla/qibla_compass_page.dart';
import '../../features/settings/screens/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  static const int _homeIndex = 0;

  int _index = 0;

  Widget _buildCurrentPage() {
    switch (_index) {
      case 0:
        return const HomeScreen();
      case 1:
        return QuranIndexScreen();
      case 2:
        return const QiblaCompassPage();
      case 3:
        return const FavoritesScreen();
      case 4:
        return const PrayerTimesScreen();
      case 5:
        return const SettingsScreen();
      default:
        return const HomeScreen();
    }
  }

  void _onTabSelected(int value) {
    if (value != _homeIndex) {
      context.read<AdhkarProvider>().clearSearch();
    }
    if (value == _index) return;

    // A tab switch happens inside a single route, so the automatic
    // route-based suppression never fires. Suppress the glass material
    // manually for the duration of the fade transition.
    if (supportsLiquidGlass) {
      withGlassSuppressed(() async {
        setState(() => _index = value);
        await Future<void>.delayed(const Duration(milliseconds: 250));
      });
    } else {
      setState(() => _index = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: _buildCurrentPage(),
        ),
      ),
      bottomNavigationBar: useNativeIOSSystemUI
          ? LiquidGlassTabBar(
              items: const [
                LiquidGlassTabItem(
                  label: 'الرئيسية',
                  icon: NativeLiquidGlassIcon.sfSymbol('house'),
                  selectedIcon: NativeLiquidGlassIcon.sfSymbol('house.fill'),
                ),
                LiquidGlassTabItem(
                  label: 'القرآن',
                  icon: NativeLiquidGlassIcon.sfSymbol('book'),
                  selectedIcon: NativeLiquidGlassIcon.sfSymbol('book.fill'),
                ),
                LiquidGlassTabItem(
                  label: 'القبلة',
                  icon: NativeLiquidGlassIcon.sfSymbol('location'),
                  selectedIcon: NativeLiquidGlassIcon.sfSymbol('location.fill'),
                ),
                LiquidGlassTabItem(
                  label: 'المفضلة',
                  icon: NativeLiquidGlassIcon.sfSymbol('heart'),
                  selectedIcon: NativeLiquidGlassIcon.sfSymbol('heart.fill'),
                ),
                LiquidGlassTabItem(
                  label: 'الآذان',
                  icon: NativeLiquidGlassIcon.sfSymbol('clock'),
                  selectedIcon: NativeLiquidGlassIcon.sfSymbol('clock.fill'),
                ),
                LiquidGlassTabItem(
                  label: 'الإعدادات',
                  icon: NativeLiquidGlassIcon.sfSymbol('gearshape'),
                  selectedIcon:
                      NativeLiquidGlassIcon.sfSymbol('gearshape.fill'),
                ),
              ],
              currentIndex: _index,
              onTabSelected: _onTabSelected,
              selectedItemColor: Theme.of(context).colorScheme.primary,
            )
          : NavigationBar(
              selectedIndex: _index,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: _onTabSelected,
              destinations: const [
                NavigationDestination(
                  icon: Icon(OctIcons.home),
                  selectedIcon: Icon(OctIcons.home_fill),
                  label: 'الرئيسية',
                ),
                NavigationDestination(
                  icon: Icon(OctIcons.book),
                  selectedIcon: Icon(OctIcons.book),
                  label: 'القرآن',
                ),
                NavigationDestination(
                  icon: Icon(OctIcons.location),
                  selectedIcon: Icon(OctIcons.location_fill),
                  label: 'القبلة',
                ),
                NavigationDestination(
                  icon: Icon(OctIcons.heart),
                  selectedIcon: Icon(OctIcons.heart_fill),
                  label: 'المفضلة',
                ),
                NavigationDestination(
                  icon: Icon(OctIcons.clock),
                  selectedIcon: Icon(OctIcons.clock_fill),
                  label: 'الآذان',
                ),
                NavigationDestination(
                  icon: Icon(OctIcons.gear),
                  selectedIcon: Icon(OctIcons.gear_fill),
                  label: 'الإعدادات',
                ),
              ],
            ),
    );
  }
}
