import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/energy_display.dart';
import 'package:opennutritracker/features/add_meal/presentation/log_tray.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The "To log" list on the add-food screen: what has been picked so far,
/// each with a way to take it off again.
class LogTrayList extends StatelessWidget {
  final LogTray tray;

  const LogTrayList({super.key, required this.tray});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
    final accent = Theme.of(context).colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;
    final items = tray.items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: Dimens.spacing4),
          child: Row(
            children: [
              // One line beside Clear at any text size (AGENTS.md, row
              // titles): it shrinks before it ellipsizes.
              Expanded(
                child: AutoSizeText(
                  S.of(context).logTrayTitle(items.length).toUpperCase(),
                  maxLines: 1,
                  minFontSize: 10,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Semantics(
                identifier: 'add-meal-tray-clear',
                child: TextButton(
                  onPressed: tray.clear,
                  style: TextButton.styleFrom(
                    foregroundColor: palette.textMuted,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(S.of(context).profileTargetWeightClearAction),
                ),
              ),
            ],
          ),
        ),
        // A fixed set of rows, not a builder: the list is labelled as a
        // whole, the way the result lists below it are.
        Semantics(
          identifier: 'add-meal-tray-list',
          container: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(top: Dimens.spacing8),
                  child: _LogTrayRow(
                    item: items[i],
                    onRemove: () => tray.removeAt(i),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogTrayRow extends StatelessWidget {
  final LogTrayItem item;
  final VoidCallback onRemove;

  const _LogTrayRow({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
    final accent = Theme.of(context).colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        border: Border.all(
          color: accent.withValues(alpha: 0.45),
          width: Dimens.hairline,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: Dimens.borderRadiusS,
            ),
            child: Icon(Icons.restaurant_rounded, size: 20, color: accent),
          ),
          const SizedBox(width: Dimens.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  item.meal.name ?? '?',
                  maxLines: 1,
                  minFontSize: 12,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${item.amountLabel} · '
                  '${logTrayKcalLabel(context, item.kcal)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // One identifier for every row's control: the rows are found by
          // their food's name, and an index in the id would shift whenever
          // an earlier row is removed.
          Semantics(
            identifier: 'add-meal-tray-remove',
            child: IconButton(
              onPressed: onRemove,
              tooltip: S.of(context).logTrayRemoveLabel,
              icon: Icon(Icons.close_rounded, color: palette.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// The one button that writes the whole list to the diary.
class LogTrayLogButton extends StatelessWidget {
  final LogTray tray;
  final VoidCallback? onPressed;

  const LogTrayLogButton({
    super.key,
    required this.tray,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = S.of(context).bulkAddSubmitLabel(tray.length);
    // The sum of the rows as shown above it, not the rounded exact sum,
    // so the list adds up on screen (#1469).
    final kcal = EnergyDisplay.formatSumWithUnit(
      context,
      tray.items.map((item) => item.kcal),
    );
    return Semantics(
      identifier: 'add-meal-tray-log',
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          shape: const StadiumBorder(),
        ),
        // Label and total share the line where they fit; at large text
        // sizes the total wraps under the label rather than squeezing it.
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_rounded),
                const SizedBox(width: 8),
                Flexible(child: Text(label)),
              ],
            ),
            Text(kcal, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
