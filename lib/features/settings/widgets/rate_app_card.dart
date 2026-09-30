import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_icons.dart';

const String kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.hussein.almufradun';

class RateAppCard extends StatelessWidget {
  const RateAppCard({super.key});

  @override
  Widget build(BuildContext context) {
    // No App Store ID exists for this app yet, so the rating flow is
    // Android-only. Rendering the card on iOS would silently fail on iOS
    // (the Google Play link cannot open a review destination there).
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(OctIcons.star, color: colorScheme.onSurfaceVariant),
        title: Text(
          'قيّم التطبيق',
          style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
        ),
        subtitle: Text(
          'قيّمنا على متجر Google Play',
          style: textTheme.bodySmall
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        trailing: Icon(
          OctIcons.arrow_right,
          size: 18,
          color: colorScheme.onSurfaceVariant,
        ),
        onTap: () => _showRateDialog(context, textTheme, colorScheme),
      ),
    );
  }

  void _showRateDialog(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          OctIcons.star,
          size: 48,
          color: colorScheme.primary,
        ),
        title: const Text('قيّم التطبيق'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'هل أعجبك التطبيق؟ شاركنا رأيك',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'تقييمك يساعدنا على تحسين التطبيق ونشر الخير',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              final uri = Uri.parse(kPlayStoreUrl);
              launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: const Text('قيّم الآن'),
          ),
        ],
      ),
    );
  }
}