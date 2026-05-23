import 'package:flutter/material.dart';
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

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final projected = dayKcalConsumed + currentSelectionKcal;

    final consumedFactor = (dayKcalConsumed / dayKcalGoal).clamp(0.0, 1.0);
    final projectedFactor = (projected / dayKcalGoal).clamp(0.0, 1.0);

    final hasLiveSelection = currentSelectionKcal > 0;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: colorScheme.primary.withValues(alpha: 0.15)),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: projectedFactor,
                    child: Container(
                      color: colorScheme.primary.withValues(alpha: 0.45),
                    ),
                  ),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: consumedFactor,
                    child: Container(color: colorScheme.primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            S.of(context).mealDetailDayTotalLabel(
                  projected.toStringAsFixed(0),
                  dayKcalGoal.toStringAsFixed(0),
                ),
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (hasLiveSelection) ...[
            const SizedBox(height: 2),
            Text(
              S.of(context).mealDetailCurrentSelectionLabel(
                    currentSelectionKcal.toStringAsFixed(0),
                  ),
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
