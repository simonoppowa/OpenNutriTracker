import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class OnboardingOverviewPageBody extends StatelessWidget {
  final String calorieGoalDayString;
  final Function(bool active) setButtonActive;
  final double? totalKcalCalculated;

  const OnboardingOverviewPageBody(
      {Key? key, required this.setButtonActive, this.totalKcalCalculated, required this.calorieGoalDayString})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.of(context).onboardingOverviewLabel,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 32.0),
          Text(S.of(context).onboardingYourGoalLabel,
              style: Theme.of(context).textTheme.bodyLarge),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(calorieGoalDayString,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary)),
                Text(S.of(context).onboardingKcalPerDayLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onBackground
                            .withOpacity(0.6)))
              ],
            ),
          ),
          const SizedBox(height: 16.0)
        ],
      ),
    );
  }
}
