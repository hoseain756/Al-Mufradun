import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

/// True when native UIKit components should replace the Material widgets
/// (any iOS device). On iOS < 26 the same native controls render with the
/// standard system appearance; on iOS 26+ they get Liquid Glass for free.
/// On Android/web/desktop the package widgets render nothing, so every use
/// MUST be gated with this getter.
bool get useNativeIOSSystemUI =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

/// True only on iOS 26+, where the Liquid Glass material is active. Use
/// this when behaviour must differ (e.g. manual glass suppression during
/// same-route tab transitions) rather than for widget selection.
bool get supportsLiquidGlass => NativeLiquidGlassUtils.supportsLiquidGlass;

/// Suppresses native glass views during a same-route transition (e.g. a
/// tab switch animated inside a single route) so the glass material does
/// not sample a half-rendered Flutter surface. Reference-counted; the
/// `finally` guarantees balance even if the transition throws.
Future<void> withGlassSuppressed(Future<void> Function() transition) async {
  if (!supportsLiquidGlass) {
    await transition();
    return;
  }

  await NativeLiquidGlassLifecycle.suppressGlassEffects();
  try {
    await transition();
  } finally {
    await NativeLiquidGlassLifecycle.unsuppressGlassEffects();
  }
}

/// One action of [showAdaptiveAlert].
class AdaptiveAlertAction {
  const AdaptiveAlertAction({
    required this.id,
    required this.title,
    this.isDestructive = false,
    this.isCancel = false,
  });

  final String id;
  final String title;
  final bool isDestructive;
  final bool isCancel;
}

/// Shows a native `UIAlertController` on iOS 26+ and the existing Material
/// [AlertDialog] everywhere else (iOS < 26, Android, web, desktop).
///
/// Returns the id of the tapped action, or `null` when dismissed.
Future<String?> showAdaptiveAlert({
  required BuildContext context,
  String? title,
  String? message,
  List<AdaptiveAlertAction> actions = const [],
}) {
  if (supportsLiquidGlass) {
    return LiquidGlassAlert.show(
      context: context,
      title: title,
      message: message,
      actions: [
        for (final action in actions)
          LiquidGlassAlertAction(
            id: action.id,
            title: action.title,
            isDestructive: action.isDestructive,
            isCancel: action.isCancel,
          ),
      ],
    );
  }

  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: title == null ? null : Text(title),
      content: message == null ? null : Text(message),
      actions: [
        for (final action in actions)
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(action.id),
            child: Text(action.title),
          ),
      ],
    ),
  );
}
