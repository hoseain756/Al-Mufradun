import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/adhkar_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

class AdhkarCard extends StatelessWidget {
  final AdhkarModel item;

  const AdhkarCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => _showDetailSheet(context),
      // M3: Filled Card using theme cardTheme (surfaceContainerLow, no elevation)
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // M3: Assist chip style badge
                  _M3Badge(text: item.category, isPrimary: true),
                  _M3Badge(
                    text: '${item.count.isEmpty ? "1" : item.count}x',
                    isPrimary: false,
                  ),
                ],
              ),
            ),

            // M3: Divider with outlineVariant from theme
            Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),

            // ── Body — zekr text only ─────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                item.zekr,
                style: AppTheme.zekrStyle(
                  isQuranicFont: item.isQuranicFont,
                  fontSize: provider.fontSize,
                  color: colorScheme.onSurface, // M3: onSurface
                ),
                textAlign: TextAlign.justify,
              ),
            ),

            // ── Footer ────────────────────────────────────
            // M3: Surface container for footer separation
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12), // M3: match card shape
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(OctIcons.book,
                            size: 16,
                            color: colorScheme.primary), // M3: primary
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
                      // M3: Standard icon buttons
                      _CardIconButton(
                        icon: provider.isFavorite(item)
                            ? OctIcons.heart_fill
                            : OctIcons.heart,
                        color: provider.isFavorite(item)
                            ? colorScheme
                                .error // M3: error role for active heart
                            : null,
                        onTap: () => provider.toggleFavorite(item),
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

  // ── Detail Bottom Sheet ─────────────────────────────────
  void _showDetailSheet(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<AppProvider>(context, listen: false);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      // M3: Uses theme bottomSheetTheme
      backgroundColor: colorScheme.surfaceContainerLow,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return Column(
              children: [
                // M3: Drag handle
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header badges
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _M3Badge(text: item.category, isPrimary: true),
                      _M3Badge(
                        text: '${item.count.isEmpty ? "1" : item.count}x',
                        isPrimary: false,
                      ),
                    ],
                  ),
                ),

                // M3: Divider
                const Divider(height: 1),

                // Scrollable content
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Zekr text
                      Text(
                        item.zekr,
                        style: AppTheme.zekrStyle(
                          isQuranicFont: item.isQuranicFont,
                          fontSize: provider.fontSize,
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.justify,
                      ),

                      // Description
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        // M3: Outlined container with primaryContainer tones
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer
                                .withValues(alpha: 0.3), // M3: primaryContainer
                            borderRadius:
                                BorderRadius.circular(12), // M3: Medium shape
                            border: Border.all(
                              color: colorScheme.primaryContainer,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(OctIcons.info,
                                      size: 18,
                                      color: colorScheme
                                          .onPrimaryContainer), // M3: onPrimaryContainer
                                  const SizedBox(width: 8),
                                  Text(
                                    'المرجع',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item.description,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.6,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Reference
                      if (item.reference.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        // M3: surfaceContainerHighest container
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius:
                                BorderRadius.circular(12), // M3: Medium shape
                          ),
                          child: Row(
                            children: [
                              Icon(OctIcons.book,
                                  size: 16, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.reference,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Bottom Action Bar ──────────────────────
                // M3: Surface container with top divider
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outlineVariant, // M3: outlineVariant
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _SheetActionButton(
                        icon: OctIcons.copy,
                        label: 'نسخ',
                        onTap: () {
                          _copyText(context);
                          Navigator.pop(ctx);
                        },
                      ),
                      _SheetActionButton(
                        icon: OctIcons.share,
                        label: 'مشاركة',
                        onTap: () {
                          _shareText();
                          Navigator.pop(ctx);
                        },
                      ),
                      StatefulBuilder(
                        builder: (context, setState) {
                          final isFav = provider.isFavorite(item);
                          return _SheetActionButton(
                            icon: isFav
                                ? OctIcons.heart_fill
                                : OctIcons.heart,
                            label: isFav ? 'إزالة المفضلة' : 'المفضلة',
                            color: isFav
                                ? Theme.of(context).colorScheme.error
                                : null,
                            onTap: () {
                              provider.toggleFavorite(item);
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _copyText(BuildContext context) {
    final text = '${item.shareText}\n\n${item.reference}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      // M3: SnackBar uses theme snackBarTheme
      const SnackBar(content: Text('تم النسخ')),
    );
  }

  void _shareText() {
    final text = '${item.shareText}\n\n${item.reference}';
    Share.share(text);
  }
}

// ── M3 Badge (chip-style) ─────────────────────────────────
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
        // M3: primaryContainer for primary, surfaceContainerHighest for secondary
        color: isPrimary
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8), // M3: Small shape
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              // M3: onPrimaryContainer / onSurfaceVariant
              color: isPrimary
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

// ── M3 Card Icon Button ───────────────────────────────────
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
      color: color ?? colorScheme.onSurfaceVariant, // M3: onSurfaceVariant
      // M3: state layers handled by theme iconButtonTheme
      visualDensity: VisualDensity.compact, // tighter spacing in footer
    );
  }
}

// ── M3 Sheet Action Button ────────────────────────────────
class _SheetActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SheetActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveColor = color ?? colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12), // M3: Medium shape
      // M3: state layer
      splashColor: effectiveColor.withValues(alpha: 0.08),
      highlightColor: effectiveColor.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: effectiveColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
