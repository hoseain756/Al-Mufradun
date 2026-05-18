import 'package:flutter/material.dart';
import '../theme/app_icons.dart';

import 'favorites_screen.dart';
import 'home_screen.dart';
import 'prayer_times_screen.dart';
import 'qibla_compass_page.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _index = 2;

  Widget _buildCurrentPage() {
    switch (_index) {
      case 0:
        return const QiblaCompassPage();
      case 1:
        return const FavoritesScreen();
      case 2:
        return const HomeScreen();
      case 3:
        return const PrayerTimesScreen();
      case 4:
        return const SettingsScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentPage(),
      bottomNavigationBar: NavigationBar(
        height: 70,
        selectedIndex: _index,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (value) {
          setState(() => _index = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(OctIcons.location),
            selectedIcon: Icon(OctIcons.location),
            label: 'القبلة',
          ),
          NavigationDestination(
            icon: Icon(OctIcons.heart),
            selectedIcon: Icon(OctIcons.heart_fill),
            label: 'المفضلة',
          ),
          NavigationDestination(
            icon: Icon(OctIcons.home),
            selectedIcon: Icon(OctIcons.home),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(OctIcons.clock),
            selectedIcon: Icon(OctIcons.clock),
            label: 'الآذان',
          ),
          NavigationDestination(
            icon: Icon(OctIcons.gear),
            selectedIcon: Icon(OctIcons.gear),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}
