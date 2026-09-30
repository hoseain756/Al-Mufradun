import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/app_settings_provider.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../adhkar_provider.dart';
import '../models/adhkar_model.dart';
import 'dhikr_detail_sheet.dart';

class AdhkarCard extends StatelessWidget {
  final AdhkarModel item;
  final List<AdhkarModel>? categoryList;
  final int? indexInCategory;

  const AdhkarCard({
    super.key,
    required this.item,
    this.categoryList,
    this.indexInCategory,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdhkarProvider>(context);
    final settings = Provider.of<AppSettingsProvider>(context);
    final fontSize = settings.fontSize;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => _showDetailSheet(context),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.category,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _DhikrStatusBadge(item: item),
                ],
              ),
            ),

            Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                item.zekr,
                style: AppTheme.zekrStyle(
                  isQuranicFont: item.isQuranicFont,
                  fontSize: fontSize,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.justify,
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(OctIcons.book, size: 16, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.reference.isEmpty ? 'المصدر' : item.reference,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _CardIconButton(
                        icon: provider.isFavorite(item)
                            ? OctIcons.heart_fill
                            : OctIcons.heart,
                        color: provider.isFavorite(item)
                            ? colorScheme.error
                            : null,
                        onTap: () => _toggleFavoriteWithUndo(context),
                      ),
                      _CardIconButton(
                        icon: OctIcons.copy,
                        onTap: () => _copyText(context),
                      ),
                      _CardIconButton(
                        icon: OctIcons.share,
                        onTap: () => _shareText(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleFavoriteWithUndo(BuildContext context) {
    final provider = context.read<AdhkarProvider>();
    final wasFavorite = provider.isFavorite(item);
    provider.toggleFavorite(item);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasFavorite ? 'تم إزالة الذكر من المفضلة' : 'تم إضافة الذكر إلى المفضلة',
        ),
        action: SnackBarAction(
          label: 'تراجع',
          onPressed: () => provider.toggleFavorite(item),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showDetailSheet(BuildContext context) {
    final provider = Provider.of<AdhkarProvider>(context, listen: false);
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: colorScheme.surfaceContainerLow,
      builder: (ctx) {
        return DhikrDetailSheet(
          item: item,
          provider: provider,
          settings: settings,
          categoryList: categoryList,
          indexInCategory: indexInCategory,
        );
      },
    );
  }

  void _copyText(BuildContext context) {
    final text = '${item.shareText}\n\n${item.reference}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم النسخ')),
    );
  }

  void _shareText() {
    final text = '${item.shareText}\n\n${item.reference}';
    Share.share(text);
  }
}

// ── Dhikr Status Badge (on card header) ──────────────────────
class _DhikrStatusBadge extends StatelessWidget {
  final AdhkarModel item;

  const _DhikrStatusBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdhkarProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final target = item.countInt;
    final current = provider.getDhikrCount(item.id);

    if (current >= target) {
      // Completed
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'مكتمل',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onTertiaryContainer,
              ),
        ),
      );
    } else if (current > 0) {
      // In progress
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${target - current} / $target',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
        ),
      );
    } else {
      // Not started
      return _M3Badge(
        text: '${item.count.isEmpty ? "1" : item.count}x',
        isPrimary: false,
      );
    }
  }
}

// ── M3 Badge (chip-style) ────────────────────────────────────
class _M3Badge extends StatelessWidget {
  final String text;
  final bool isPrimary;

  const _M3Badge({required this.text, required this.isPrimary});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isPrimary
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

// ── M3 Card Icon Button ──────────────────────────────────────
class _CardIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _CardIconButton({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      color: color ?? colorScheme.onSurfaceVariant,
      visualDensity: VisualDensity.compact,
    );
  }
}
