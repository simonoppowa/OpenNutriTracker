import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

class OnboardingOverviewPageBody extends StatelessWidget {
  final String calorieGoalDayString;
  final String carbsGoalString;
  final String fatGoalString;
  final String proteinGoalString;
  final Function(bool active) setButtonActive;
  final double? totalKcalCalculated;

  const OnboardingOverviewPageBody({
    super.key,
    required this.setButtonActive,
    this.totalKcalCalculated,
    required this.calorieGoalDayString,
    required this.carbsGoalString,
    required this.fatGoalString,
    required this.proteinGoalString,
  });

  @override
  Widget build(BuildContext context) {
    // #177: Stored calorie goal is always in kcal; only the displayed
    // number and unit-suffix change when the user prefers kJ.
    final usesKilojoules = context.watch<EnergyUnitProvider>().usesKilojoules;
    final parsedKcalGoal = double.tryParse(calorieGoalDayString) ?? 0;
    final displayGoalString = usesKilojoules
        ? UnitCalc.kcalToKj(parsedKcalGoal).toInt().toString()
        : calorieGoalDayString;
    final perDayLabel = usesKilojoules
        ? S.of(context).onboardingKjPerDayLabel
        : S.of(context).onboardingKcalPerDayLabel;
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).onboardingOverviewLabel,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32.0),
          Text(
            S.of(context).onboardingYourGoalLabel,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8.0),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  displayGoalString,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                Text(
                  perDayLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32.0),
          Text(
            S.of(context).onboardingYourMacrosGoalLabel,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16.0),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$carbsGoalString g',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  S.of(context).carbsLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  '$fatGoalString g',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
                Text(
                  S.of(context).fatLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  '$proteinGoalString g',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
                Text(
                  S.of(context).proteinLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
