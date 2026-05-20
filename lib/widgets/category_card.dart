import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
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
    final provider = Provider.of<AppProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final icon = _getCategoryIcon(category);
    final iconColor = _getCategoryColor(context, category);
    final progress = provider.getCategoryProgress(category);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: iconColor.withValues(alpha: 0.08),
        highlightColor: iconColor.withValues(alpha: 0.12),
        child: Stack(
          children: [
            // Decorative background icon
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                  Text(
                    category,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (progress > 0) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        color: iconColor,
                      ),
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
