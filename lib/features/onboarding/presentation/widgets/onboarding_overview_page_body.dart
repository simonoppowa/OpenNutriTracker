import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/kcal_goal_breakdown_entity.dart';
import 'package:opennutritracker/core/presentation/sources_screen.dart';
import 'package:opennutritracker/core/presentation/widgets/low_kcal_warning_card.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/energy_display.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/kcal_goal_info_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

class OnboardingOverviewPageBody extends StatelessWidget {
  final String calorieGoalDayString;
  final String carbsGoalString;
  final String fatGoalString;
  final String proteinGoalString;
  final Function(bool active) setButtonActive;
  final double? totalKcalCalculated;
  final bool showLowKcalWarning;
  final double lowKcalWarningThreshold;

  /// The derivation behind [calorieGoalDayString]. Null while the selection
  /// is still incomplete, in which case the page shows the goal alone.
  final KcalGoalBreakdownEntity? breakdown;

  const OnboardingOverviewPageBody({
    super.key,
    required this.setButtonActive,
    this.totalKcalCalculated,
    required this.calorieGoalDayString,
    required this.carbsGoalString,
    required this.fatGoalString,
    required this.proteinGoalString,
    this.showLowKcalWarning = false,
    this.lowKcalWarningThreshold = 0,
    this.breakdown,
  });

  @override
  Widget build(BuildContext context) {
    // #177: Stored calorie goal is always in kcal; only the displayed
    // number and unit-suffix change when the user prefers kJ.
    final usesKilojoules = context.watch<EnergyUnitProvider>().usesKilojoules;
    final parsedKcalGoal = double.tryParse(calorieGoalDayString) ?? 0;
    final displayGoalString = usesKilojoules
        ? UnitCalc.kcalToKj(parsedKcalGoal).round().toString()
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
          if (breakdown != null) ...[
            const SizedBox(height: 16.0),
            _buildDerivation(context, breakdown!),
          ],
          if (showLowKcalWarning) ...[
            const SizedBox(height: 24.0),
            LowKcalWarningCard(
              thresholdKcal: lowKcalWarningThreshold,
              margin: EdgeInsets.zero,
            ),
          ],
          const SizedBox(height: 32.0),
          Text(
            S.of(context).onboardingYourMacrosGoalLabel,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8.0),
          _buildMacroSummary(context),
          const SizedBox(height: 24.0),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SourcesScreen()),
              ),
              icon: const Icon(Icons.menu_book_outlined),
              label: Text(S.of(context).settingsSourcesLabel),
            ),
          ),
        ],
      ),
    );
  }

  /// The gram targets as one read-only summary.
  ///
  /// They used to be three large accent-coloured numbers, each over its own
  /// label, which read as input boxes that did nothing when tapped (#1324).
  /// Laid out like the derivation above and with a pointer to where they can
  /// be changed, they read as results.
  Widget _buildMacroSummary(BuildContext context) {
    final s = S.of(context);
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMacroRow(context, s.carbsLabel, carbsGoalString),
          const SizedBox(height: 4.0),
          _buildMacroRow(context, s.fatLabel, fatGoalString),
          const SizedBox(height: 4.0),
          _buildMacroRow(context, s.proteinLabel, proteinGoalString),
          const SizedBox(height: 8.0),
          Text(
            s.onboardingMacrosChangeLaterHint(
              s.settingsCategoryGoals,
              s.settingsMacroSplitLabel,
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRow(BuildContext context, String label, String grams) {
    return MergeSemantics(
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8.0),
          Text(
            '$grams g',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  /// The arithmetic behind the headline number, in the order the app applies
  /// it, with a link to the full derivation.
  Widget _buildDerivation(
    BuildContext context,
    KcalGoalBreakdownEntity breakdown,
  ) {
    final adjustment = breakdown.effectiveAdjustmentKcal;
    // The sign stays visible. This is the step that turns maintenance
    // energy into a goal, so its direction matters.
    final adjustmentPrefix = adjustment > 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDerivationRow(
            context,
            S.of(context).kcalGoalInfoTdeeResultLabel,
            EnergyDisplay.formatWithUnit(context, breakdown.tdeeKcal),
          ),
          const SizedBox(height: 4.0),
          _buildDerivationRow(
            context,
            S.of(context).kcalGoalInfoAppliedAdjustmentLabel,
            '$adjustmentPrefix'
            '${EnergyDisplay.formatWithUnit(context, adjustment)}',
          ),
          const Divider(height: 16.0),
          _buildDerivationRow(
            context,
            S.of(context).kcalGoalInfoResultSection,
            EnergyDisplay.formatWithUnit(context, breakdown.totalKcalGoal),
            emphasised: true,
          ),
          const SizedBox(height: 4.0),
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              identifier: 'onboarding-overview-calculation',
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => KcalGoalInfoScreen(breakdown: breakdown),
                  ),
                ),
                icon: const Icon(Icons.calculate_outlined, size: 18),
                label: Text(S.of(context).settingsKcalGoalInfoLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDerivationRow(
    BuildContext context,
    String label,
    String value, {
    bool emphasised = false,
  }) {
    final style = emphasised
        ? Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          )
        : Theme.of(context).textTheme.bodySmall;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: style,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8.0),
        Text(value, style: style),
      ],
    );
  }
}
