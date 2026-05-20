import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_icons.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            centerTitle: false,
            title: Text('الإعدادات'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Font Size Section ─────────────────────
                // M3: Filled Card with surfaceContainerLow
                Card(
                  // M3: Medium shape from theme
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'حجم الخط',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface, // M3: onSurface
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // M3: Tonal IconButton
                            IconButton.filledTonal(
                              icon: const Icon(OctIcons.plus),
                              tooltip: 'تكبير الخط',
                              onPressed: () => provider.adjustFontSize(2),
                            ),
                            const SizedBox(width: 16),
                            // M3: Display font size in bodyLarge
                            Text(
                              provider.fontSize.toStringAsFixed(0),
                              style: textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // M3: Tonal IconButton
                            IconButton.filledTonal(
                              icon: const Icon(OctIcons.dash),
                              tooltip: 'تصغير الخط',
                              onPressed: () => provider.adjustFontSize(-2),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Theme Mode Section ────────────────────
                // M3: Filled Card with SegmentedButton for system/light/dark
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              provider.themeMode == ThemeMode.dark
                                  ? OctIcons.moon
                                  : provider.themeMode == ThemeMode.light
                                      ? OctIcons.sun
                                      : OctIcons.gear,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'المظهر',
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<ThemeMode>(
                            segments: const [
                              ButtonSegment(
                                value: ThemeMode.system,
                                label: Text('تلقائي'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.light,
                                label: Text('فاتح'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                label: Text('داكن'),
                              ),
                            ],
                            selected: {provider.themeMode},
                            onSelectionChanged: (selected) {
                              provider.setThemeMode(selected.first);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
