import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/training_plan.dart';
import 'package:opennutritracker/features/goals/domain/auto_training_day_usecase.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// After the user logged an activity on [day] (#36): switches the day to a
/// training day when they chose that, or asks with a snackbar action when
/// they chose to be asked. The answer is checked again when the user takes
/// it, so a day they set by hand meanwhile keeps its type. [messenger] and
/// [l10n] are resolved before the screen that logged the activity closes.
Future<void> offerTrainingDayAfterActivity({
  required AutoTrainingDayUsecase usecase,
  required ScaffoldMessengerState messenger,
  required S l10n,
  required DateTime day,
}) async {
  switch (await usecase.decide(day)) {
    case AutoTrainingDayDecision.none:
      return;
    case AutoTrainingDayDecision.switchToTraining:
      await usecase.switchToTraining(day);
      messenger.showSnackBar(SnackBar(content: Text(l10n.trainingDaySwitched)));
    case AutoTrainingDayDecision.suggest:
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.trainingDaySuggestion),
          action: SnackBarAction(
            label: l10n.trainingDaySuggestionAction,
            onPressed: () async {
              if (await usecase.decide(day) != AutoTrainingDayDecision.none) {
                await usecase.switchToTraining(day);
              }
            },
          ),
        ),
      );
  }
}
