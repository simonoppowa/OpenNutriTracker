import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/generated/l10n.dart';

class DailyKcalOverview extends StatelessWidget {
  final double dayKcalConsumed;
  final double dayKcalGoal;
  final double currentSelectionKcal;

  const DailyKcalOverview({
    super.key,
    required this.dayKcalConsumed,
    required this.dayKcalGoal,
    required this.currentSelectionKcal,
  });

  @override
  Widget build(BuildContext context) {
    if (dayKcalGoal <= 0) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final accent = Theme.of(context).colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;

    final projected = dayKcalConsumed + currentSelectionKcal;

    final consumedFactor = (dayKcalConsumed / dayKcalGoal).clamp(0.0, 1.0);
    final projectedFactor = (projected / dayKcalGoal).clamp(0.0, 1.0);

    final hasLiveSelection = currentSelectionKcal > 0;

    return Container(
      color: palette.surface,
      padding: const EdgeInsets.fromLTRB(
        Dimens.spacing16,
        Dimens.spacing8,
        Dimens.spacing16,
        Dimens.spacing8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Dimens.radiusS),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: palette.surfaceMuted),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: projectedFactor,
                    child: Container(color: accent.withValues(alpha: 0.45)),
                  ),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: consumedFactor,
                    child: Container(color: accent),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Dimens.spacing8),
          Text(
            S.of(context).mealDetailDayTotalLabel(
                  projected.toStringAsFixed(0),
                  dayKcalGoal.toStringAsFixed(0),
                ),
            style: textTheme.labelLarge?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          if (hasLiveSelection) ...[
            const SizedBox(height: Dimens.spacing4),
            Text(
              S.of(context).mealDetailCurrentSelectionLabel(
                    currentSelectionKcal.toStringAsFixed(0),
                  ),
              style: textTheme.labelSmall?.copyWith(color: palette.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
