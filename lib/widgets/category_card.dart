import 'package:flutter/material.dart';
import '../theme/app_icons.dart';

class CategoryCard extends StatelessWidget {
  final String category;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  IconData _getCategoryIcon(String category) {
    if (category.contains('الصباح')) return OctIcons.sun;
    if (category.contains('المساء')) return OctIcons.moon;
    if (category.contains('النوم') || category.contains('الاستيقاظ')) {
      return OctIcons.light_bulb;
    }
    if (category.contains('الصلاة') || category.contains('مسجد')) {
      return OctIcons.organization;
    }
    if (category.contains('وضوء')) return OctIcons.beaker;
    if (category.contains('منزل')) return OctIcons.home;
    if (category.contains('خلاء')) return OctIcons.home;
    if (category.contains('أذان')) return OctIcons.unmute;
    if (category.contains('ثوب')) return OctIcons.star;

    return OctIcons.file_directory;
  }

  Color _getCategoryColor(BuildContext context, String category) {
    final scheme = Theme.of(context).colorScheme;
    if (category.contains('الصباح')) return Colors.orange;
    if (category.contains('المساء')) return Colors.indigo;
    return scheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final icon = _getCategoryIcon(category);
    final iconColor = _getCategoryColor(context, category);

    // M3: Filled Card with surface tint instead of drop shadow
    return Card(
      // M3: surfaceContainerLow from theme cardTheme
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        // M3: state layer with splashColor
        splashColor: iconColor.withValues(alpha: 0.08), // M3: hover 8%
        highlightColor: iconColor.withValues(alpha: 0.12), // M3: pressed 12%
        child: Stack(
          children: [
            // Decorative background icon (faded)
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                icon,
                size: 80,
                color: iconColor.withValues(alpha: 0.06),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0), // M3: 16dp padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // M3: Icon container with primaryContainer-style tint
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 28,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // M3: titleMedium for card titles
                  Text(
                    category,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface, // M3: onSurface
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
