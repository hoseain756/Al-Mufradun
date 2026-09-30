import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/app_settings_provider.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../adhkar_provider.dart';
import '../models/adhkar_model.dart';

// ── Detail Sheet with Dhikr Counter ──────────────────────────
class DhikrDetailSheet extends StatefulWidget {
  final AdhkarModel item;
  final AdhkarProvider provider;
  final AppSettingsProvider settings;
  final List<AdhkarModel>? categoryList;
  final int? indexInCategory;

  const DhikrDetailSheet({
    super.key,
    required this.item,
    required this.provider,
    required this.settings,
    this.categoryList,
    this.indexInCategory,
  });

  @override
  State<DhikrDetailSheet> createState() => _DhikrDetailSheetState();
}

class _DhikrDetailSheetState extends State<DhikrDetailSheet>
    with SingleTickerProviderStateMixin {
  late int _currentCount;
  late int _targetCount;
  bool _completed = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _targetCount = widget.item.countInt;
    _currentCount = widget.provider.getDhikrCount(widget.item.id);
    _completed = _currentCount >= _targetCount;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutBack),
    );
    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_completed) return;

    final newCount = widget.provider.incrementDhikrCount(
      widget.item.id,
      target: _targetCount,
    );
    setState(() {
      _currentCount = newCount;
    });

    HapticFeedback.lightImpact();

    if (_currentCount >= _targetCount) {
      setState(() => _completed = true);
      HapticFeedback.mediumImpact();
      _pulseController.forward();

      // Auto-advance after delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        Navigator.pop(context);
        _tryAutoAdvance();
      });
    }
  }

  void _tryAutoAdvance() {
    final list = widget.categoryList;
    final idx = widget.indexInCategory;
    if (list == null || idx == null) return;
    if (idx + 1 >= list.length) return;

    final nextItem = list[idx + 1];
    final parentContext = context;
    if (!parentContext.mounted) return;

    // Small delay so the sheet close animation completes
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!parentContext.mounted) return;
        final colorScheme = Theme.of(parentContext).colorScheme;
        showModalBottomSheet(
          context: parentContext,
          isScrollControlled: true,
          isDismissible: true,
          enableDrag: true,
          backgroundColor: colorScheme.surfaceContainerLow,
          builder: (ctx) {
            return DhikrDetailSheet(
              item: nextItem,
              provider: widget.provider,
              settings: widget.settings,
              categoryList: list,
              indexInCategory: idx + 1,
            );
          },
        );
      });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) {
        return Column(
          children: [
            // Drag handle
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

            // Header with counter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.item.category,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _CounterRing(
                    current: _currentCount,
                    target: _targetCount,
                    completed: _completed,
                    pulseAnimation: _pulseAnimation,
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Tap-to-count body
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onTap,
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Tap hint
                    if (!_completed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Center(
                          child: Text(
                            'اضغط للعدّ',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),

                    // Zekr text
                    Text(
                      widget.item.zekr,
                      style: AppTheme.zekrStyle(
                        isQuranicFont: widget.item.isQuranicFont,
                        fontSize: widget.settings.fontSize,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.justify,
                    ),

                    // Description
                    if (widget.item.description.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.primaryContainer),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(OctIcons.info,
                                    size: 18,
                                    color: colorScheme.onPrimaryContainer),
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
                              widget.item.description,
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
                    if (widget.item.reference.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(OctIcons.book,
                                size: 16, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.item.reference,
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
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SheetActionButton(
                    icon: OctIcons.copy,
                    label: 'نسخ',
                    onTap: () {
                      final text =
                          '${widget.item.shareText}\n\n${widget.item.reference}';
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم النسخ')),
                      );
                    },
                  ),
                  _SheetActionButton(
                    icon: OctIcons.share,
                    label: 'مشاركة',
                    onTap: () {
                      final text =
                          '${widget.item.shareText}\n\n${widget.item.reference}';
                      Share.share(text);
                    },
                  ),
                  StatefulBuilder(
                    builder: (context, setFavState) {
                      final isFav = widget.provider.isFavorite(widget.item);
                      return _SheetActionButton(
                        icon: isFav ? OctIcons.heart_fill : OctIcons.heart,
                        label: isFav ? 'إزالة المفضلة' : 'المفضلة',
                        color: isFav ? colorScheme.error : null,
                        onTap: () {
                          widget.provider.toggleFavorite(widget.item);
                          setFavState(() {});
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
  }
}

// ── Counter Ring Widget ──────────────────────────────────────
class _CounterRing extends StatelessWidget {
  final int current;
  final int target;
  final bool completed;
  final Animation<double> pulseAnimation;

  const _CounterRing({
    required this.current,
    required this.target,
    required this.completed,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final remaining = (target - current).clamp(0, target);
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 1.0;

    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: pulseAnimation.value,
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  color: completed
                      ? colorScheme.tertiary
                      : colorScheme.primary,
                ),
                if (completed)
                  Icon(Icons.check, size: 20, color: colorScheme.tertiary)
                else
                  Text(
                    '$remaining',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                        ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '/ $target',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

// ── M3 Sheet Action Button ───────────────────────────────────
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
      borderRadius: BorderRadius.circular(12),
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