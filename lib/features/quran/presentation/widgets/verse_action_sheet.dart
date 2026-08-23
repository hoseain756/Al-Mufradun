import 'package:flutter/material.dart';

import '../../domain/entities/surah.dart';
import '../../domain/entities/verse.dart';
import '../actions/verse_action_controller.dart';
import '../actions/verse_action_models.dart';
import '../utils/verse_action_formatter.dart';

class VerseActionSheet extends StatelessWidget {
  const VerseActionSheet({
    super.key,
    required this.actionContext,
    required this.actions,
    required this.onActionSelected,
  });

  final VerseActionContext actionContext;
  final List<VerseActionCommand> actions;
  final ValueChanged<VerseActionCommand> onActionSelected;

  static Future<void> show({
    required BuildContext context,
    required Verse verse,
    required Surah surah,
    Set<String> bookmarkedVerseIds = const <String>{},
    VerseActionController? controller,
  }) {
    return showForContext(
      context: context,
      actionContext: VerseActionContext.single(
        verse: verse,
        surah: surah,
        bookmarkedVerseIds: bookmarkedVerseIds,
      ),
      controller: controller,
    );
  }

  static Future<void> showForContext({
    required BuildContext context,
    required VerseActionContext actionContext,
    VerseActionController? controller,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final actionController = controller ?? VerseActionController();
    final actions = actionController.actionsFor(actionContext);

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: colorScheme.surfaceContainerLow,
      builder: (sheetContext) {
        return VerseActionSheet(
          actionContext: actionContext,
          actions: actions,
          onActionSelected: (command) {
            actionController.execute(
              parentContext: context,
              sheetContext: sheetContext,
              actionContext: actionContext,
              command: command,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'إجراءات الآية',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                VerseActionFormatter.formatSelectionSummary(actionContext),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              for (final action in actions)
                _VerseActionTile(
                  action: action,
                  onTap: () => onActionSelected(action),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerseActionTile extends StatelessWidget {
  const _VerseActionTile({
    required this.action,
    required this.onTap,
  });

  final VerseActionCommand action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: Icon(action.icon, color: colorScheme.primary),
      title: Text(
        action.label,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: action.isEnabled
              ? colorScheme.onSurface
              : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: action.disabledReason == null
          ? null
          : Text(
              action.disabledReason!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
      enabled: action.isEnabled,
      onTap: action.isEnabled ? onTap : null,
    );
  }
}
