import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/energy_display.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/goals/domain/own_goals_summary.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The summary from the app's services; null when it cannot be read, as
/// the card is only a hint above the explanation.
Future<OwnGoalsSummary?> _loadFromApp() async {
  try {
    return await OwnGoalsSummary.load(
      configRepository: locator(),
      getKcalGoalUsecase: locator(),
      getMacroGoalUsecase: locator(),
    );
  } catch (error, stackTrace) {
    Logger(
      'OwnGoalsNote',
    ).warning('Could not read the own goals', error, stackTrace);
    return null;
  }
}

/// A card above the kcal explanation saying that today's goals are the
/// user's own (#119): the fixed goal with the day's activity and the gram
/// macros. Renders nothing while the calculated goals apply.
class OwnGoalsNote extends StatefulWidget {
  final Future<OwnGoalsSummary?> Function() load;

  const OwnGoalsNote({super.key, this.load = _loadFromApp});

  @override
  State<OwnGoalsNote> createState() => _OwnGoalsNoteState();
}

class _OwnGoalsNoteState extends State<OwnGoalsNote> {
  late final Future<OwnGoalsSummary?> _summary = widget.load();

  @override
  Widget build(BuildContext context) => FutureBuilder<OwnGoalsSummary?>(
    future: _summary,
    builder: (context, snapshot) {
      final summary = snapshot.data;
      if (summary == null) return const SizedBox.shrink();
      final l10n = S.of(context);
      final theme = Theme.of(context);
      final fixed = summary.fixedKcal;
      final grams = summary.gramGoals;
      Widget row(String label, String value, {bool strong = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimens.spacing4),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              value,
              style: strong
                  ? theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )
                  : null,
            ),
          ],
        ),
      );
      return Semantics(
        identifier: 'kcal-info-own-goals',
        container: true,
        child: Padding(
          padding: const EdgeInsets.only(bottom: Dimens.spacing16),
          child: AppCard(
            padding: const EdgeInsets.all(Dimens.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.isTrainingDay
                      ? l10n.ownGoalsNoteTrainingTitle
                      : l10n.ownGoalsNoteTitle,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: Dimens.spacing8),
                if (fixed != null) ...[
                  row(
                    l10n.ownGoalsNoteFixedKcal,
                    EnergyDisplay.formatWithUnit(context, fixed),
                  ),
                  row(
                    l10n.activityLabel,
                    '+ ${EnergyDisplay.formatWithUnit(context, summary.kcalGoal - fixed)}',
                  ),
                  row(
                    l10n.ownGoalsNoteTotal,
                    EnergyDisplay.formatWithUnit(context, summary.kcalGoal),
                    strong: true,
                  ),
                ],
                if (grams != null) ...[
                  row(l10n.carbsLabel, '${grams.carbsG.round()} g'),
                  row(l10n.fatLabel, '${grams.fatG.round()} g'),
                  row(l10n.proteinLabel, '${grams.proteinG.round()} g'),
                ],
                const SizedBox(height: Dimens.spacing8),
                Text(
                  fixed != null
                      ? l10n.ownGoalsNoteBody
                      : l10n.ownGoalsNoteGramsOnlyBody,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
