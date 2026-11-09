import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/calories_profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/kcal_goal_breakdown_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_breakdown_usecase.dart';
import 'package:opennutritracker/core/presentation/sources_screen.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/core/utils/energy_display.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/url_const.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:opennutritracker/core/utils/safe_url_launcher.dart';
import 'package:provider/provider.dart';

/// Transparency screen: shows every variable and intermediate step behind
/// today's kcal goal, so the number on the home screen is fully auditable
/// in-app. The values come from [GetKcalGoalBreakdownUsecase], which runs
/// the exact production calculation — this screen only renders, it never
/// computes goal math of its own.
class KcalGoalInfoScreen extends StatefulWidget {
  /// Injectable for widget tests; production callers leave this null and
  /// get the locator-registered usecase.
  final GetKcalGoalBreakdownUsecase? usecase;

  /// An already-computed breakdown, used instead of fetching one.
  ///
  /// Onboarding needs this: the usecase reads the stored user and config,
  /// and during onboarding nothing has been written yet. Passing the
  /// breakdown computed from the in-progress selection means the same
  /// renderer explains the goal before and after it is saved, so the two
  /// can't drift apart.
  final KcalGoalBreakdownEntity? breakdown;

  const KcalGoalInfoScreen({super.key, this.usecase, this.breakdown});

  @override
  State<KcalGoalInfoScreen> createState() => _KcalGoalInfoScreenState();
}

class _KcalGoalInfoScreenState extends State<KcalGoalInfoScreen> {
  late final Future<KcalGoalBreakdownEntity> _breakdown;

  @override
  void initState() {
    super.initState();
    final provided = widget.breakdown;
    _breakdown = provided != null
        ? Future.value(provided)
        : (widget.usecase ?? locator<GetKcalGoalBreakdownUsecase>())
              .getBreakdown();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsKcalGoalInfoLabel)),
      body: FutureBuilder<KcalGoalBreakdownEntity>(
        future: _breakdown,
        builder: (context, snapshot) {
          final breakdown = snapshot.data;
          if (breakdown == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimens.spacing16,
              vertical: Dimens.spacing16,
            ),
            children: [
              Text(
                l10n.kcalGoalInfoIntro,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: Dimens.spacing16),
              // The short answer first (#1308); the steps below explain
              // each row.
              _SummaryCard(breakdown: breakdown),
              const SizedBox(height: Dimens.spacing12),
              _InputsCard(breakdown: breakdown),
              const SizedBox(height: Dimens.spacing12),
              _TdeeCard(breakdown: breakdown),
              const SizedBox(height: Dimens.spacing12),
              _AdjustmentCard(breakdown: breakdown),
              const SizedBox(height: Dimens.spacing12),
              _ManualAdjustmentCard(breakdown: breakdown),
              const SizedBox(height: Dimens.spacing12),
              _ActivityCard(breakdown: breakdown),
              const SizedBox(height: Dimens.spacing12),
              _MacroCard(breakdown: breakdown),
              const SizedBox(height: Dimens.spacing16),
              Text(
                l10n.kcalGoalInfoEstimateNote,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: Dimens.spacing8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SourcesScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                  label: Text(l10n.settingsSourcesLabel),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => _launchWiki(context),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(l10n.kcalGoalInfoLearnMoreLabel),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _launchWiki(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorText = S.of(context).errorOpeningBrowser;
    if (await tryLaunchExternalUrl(URLConst.wikiCalculationsURL)) return;
    messenger.showSnackBar(SnackBar(content: Text(errorText)));
  }
}

/// "Your inputs" — the profile values every later step reads from.
class _InputsCard extends StatelessWidget {
  final KcalGoalBreakdownEntity breakdown;

  const _InputsCard({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return _SectionCard(
      title: l10n.kcalGoalInfoInputsSection,
      children: [
        _ValueRow(
          label: l10n.ageLabel,
          value: l10n.yearsLabel(breakdown.age),
        ),
        _ValueRow(
          label: l10n.heightLabel,
          value: '${breakdown.heightCM.toStringAsFixed(0)} ${l10n.cmLabel}',
        ),
        _ValueRow(
          label: l10n.weightLabel,
          value: '${breakdown.weightKG.toStringAsFixed(1)} ${l10n.kgLabel}',
        ),
        _ValueRow(
          label: l10n.activityLabel,
          value: breakdown.palCategory.getName(context),
        ),
        _ValueRow(
          label: l10n.goalLabel,
          value: breakdown.goal.getName(context),
        ),
        if (breakdown.gender == UserGenderEntity.nonBinary)
          _ValueRow(
            label: l10n.caloriesProfileInfoTitle,
            // Null means "not picked yet", which the calc layer treats as
            // averaged — show the same thing it computes with.
            value: (breakdown.caloriesProfile ?? CaloriesProfileEntity.averaged)
                .getName(context),
          ),
        if (breakdown.weeklyWeightGoalKg != null)
          _ValueRow(
            label: l10n.weeklyWeightGoalLabel,
            value: l10n.weeklyWeightGoalKgPerWeek(
              breakdown.weeklyWeightGoalKg!.toStringAsFixed(2),
            ),
          ),
        if (breakdown.targetWeightKg != null)
          _ValueRow(
            label: l10n.profileTargetWeightLabel,
            value:
                '${breakdown.targetWeightKg!.toStringAsFixed(1)} ${l10n.kgLabel}',
          ),
      ],
    );
  }
}

/// Step 1 — the IOM 2005 TDEE with the user's numbers substituted in.
class _TdeeCard extends StatelessWidget {
  final KcalGoalBreakdownEntity breakdown;

  const _TdeeCard({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return _SectionCard(
      title: l10n.kcalGoalInfoTdeeSection,
      children: [
        Text(
          l10n.kcalGoalInfoTdeeExplanation,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: Dimens.spacing12),
        _ValueRow(
          label: l10n.kcalGoalInfoPalRowLabel,
          value: breakdown.palValue.toStringAsFixed(2),
        ),
        if (breakdown.paMaleFormula != null)
          _ValueRow(
            label: breakdown.usesAveragedReference
                ? '${l10n.kcalGoalInfoPaRowLabel} · ${l10n.kcalGoalInfoMaleReferenceLabel}'
                : l10n.kcalGoalInfoPaRowLabel,
            value: breakdown.paMaleFormula!.toStringAsFixed(2),
          ),
        if (breakdown.paFemaleFormula != null)
          _ValueRow(
            label: breakdown.usesAveragedReference
                ? '${l10n.kcalGoalInfoPaRowLabel} · ${l10n.kcalGoalInfoFemaleReferenceLabel}'
                : l10n.kcalGoalInfoPaRowLabel,
            value: breakdown.paFemaleFormula!.toStringAsFixed(2),
          ),
        if (breakdown.tdeeMaleReferenceKcal != null) ...[
          const SizedBox(height: Dimens.spacing8),
          if (breakdown.usesAveragedReference)
            _FormulaSideLabel(text: l10n.kcalGoalInfoMaleReferenceLabel),
          _FormulaText(
            formula: _maleFormulaText(breakdown),
            resultKcal: breakdown.tdeeMaleReferenceKcal!,
          ),
        ],
        if (breakdown.tdeeFemaleReferenceKcal != null) ...[
          const SizedBox(height: Dimens.spacing8),
          if (breakdown.usesAveragedReference)
            _FormulaSideLabel(text: l10n.kcalGoalInfoFemaleReferenceLabel),
          _FormulaText(
            formula: _femaleFormulaText(breakdown),
            resultKcal: breakdown.tdeeFemaleReferenceKcal!,
          ),
        ],
        if (breakdown.usesAveragedReference) ...[
          const SizedBox(height: Dimens.spacing8),
          Text(
            l10n.kcalGoalInfoAveragedNote,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const Divider(height: Dimens.spacing20),
        _ValueRow(
          label: l10n.kcalGoalInfoTdeeResultLabel,
          value: EnergyDisplay.formatWithUnit(context, breakdown.tdeeKcal),
          emphasized: true,
        ),
      ],
    );
  }

  // The brackets are not decoration: IOM 2005 p. 204 multiplies PA into the
  // weight *and* the height term, and this string has to show the same shape
  // the calculation uses (#987).
  String _maleFormulaText(KcalGoalBreakdownEntity b) =>
      '864 − 9.72 × ${b.age} '
      '+ ${b.paMaleFormula!.toStringAsFixed(2)} × '
      '(14.2 × ${b.weightKG.toStringAsFixed(1)} '
      '+ 503 × ${(b.heightCM / 100).toStringAsFixed(2)})';

  String _femaleFormulaText(KcalGoalBreakdownEntity b) =>
      '387 − 7.31 × ${b.age} '
      '+ ${b.paFemaleFormula!.toStringAsFixed(2)} × '
      '(10.9 × ${b.weightKG.toStringAsFixed(1)} '
      '+ 660.7 × ${(b.heightCM / 100).toStringAsFixed(2)})';
}

/// Step 2 — deficit / surplus for the weight goal, including the taper.
class _AdjustmentCard extends StatelessWidget {
  final KcalGoalBreakdownEntity breakdown;

  const _AdjustmentCard({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final usesWeeklyRate = breakdown.weeklyWeightGoalKg != null;
    return _SectionCard(
      title: l10n.kcalGoalInfoAdjustmentSection,
      children: [
        Text(
          usesWeeklyRate
              ? l10n.kcalGoalInfoAdjustmentExplanationWeekly
              : l10n.kcalGoalInfoAdjustmentExplanationFlat,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: Dimens.spacing12),
        _ValueRow(
          label: l10n.kcalGoalInfoBaseAdjustmentLabel,
          value: _signedEnergy(context, breakdown.baseAdjustmentKcal),
        ),
        if (breakdown.taperChangedAdjustment) ...[
          const SizedBox(height: Dimens.spacing8),
          Text(
            l10n.kcalGoalInfoTaperNote,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const Divider(height: Dimens.spacing20),
        _ValueRow(
          label: l10n.kcalGoalInfoAppliedAdjustmentLabel,
          value: _signedEnergy(context, breakdown.effectiveAdjustmentKcal),
          emphasized: true,
        ),
      ],
    );
  }
}

/// Step 3 — the fixed offset from Settings.
class _ManualAdjustmentCard extends StatelessWidget {
  final KcalGoalBreakdownEntity breakdown;

  const _ManualAdjustmentCard({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return _SectionCard(
      title: l10n.kcalGoalInfoManualSection,
      children: [
        Text(
          l10n.kcalGoalInfoManualExplanation,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Divider(height: Dimens.spacing20),
        _ValueRow(
          label: l10n.settingsKcalAdjustmentLabel,
          value: _signedEnergy(context, breakdown.manualKcalAdjustment),
          emphasized: true,
        ),
      ],
    );
  }
}

/// Step 4 — today's logged exercise energy.
class _ActivityCard extends StatelessWidget {
  final KcalGoalBreakdownEntity breakdown;

  const _ActivityCard({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return _SectionCard(
      title: l10n.kcalGoalInfoActivitySection,
      children: [
        Text(
          l10n.kcalGoalInfoActivityExplanation,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Divider(height: Dimens.spacing20),
        _ValueRow(
          label: l10n.activityLabel,
          value: _signedEnergy(context, breakdown.activityKcal),
          emphasized: true,
        ),
      ],
    );
  }
}

/// Today's target in a few rows (#1308): maintenance, the weight-goal
/// deficit or surplus, the manual offset and logged activities, each only
/// when it changes the number. The rows come from
/// [KcalGoalBreakdownEntity.summary], so they add up to the total shown
/// here, which is the goal Home uses.
class _SummaryCard extends StatelessWidget {
  final KcalGoalBreakdownEntity breakdown;

  const _SummaryCard({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);
    final unit = EnergyDisplay.unitLabel(context);
    final summary = breakdown.summary(
      kilojoules: context.watch<EnergyUnitProvider>().usesKilojoules,
    );
    final hasGoalRow = summary.rows.any(
      (row) => row.term == KcalGoalSummaryTerm.weightGoal,
    );
    return AppCard(
      key: const ValueKey('kcal-goal-summary'),
      padding: const EdgeInsets.all(Dimens.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final row in summary.rows)
            _ValueRow(
              label: _termLabel(context, row.term),
              value: row.term == KcalGoalSummaryTerm.maintenance
                  ? _energyText(row.value, unit)
                  : _signedEnergyText(row.value, unit),
              valueKey: ValueKey('kcal-goal-summary-${row.term.name}'),
            ),
          const Divider(height: Dimens.spacing20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  l10n.kcalGoalInfoResultSection,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: Dimens.spacing8),
              // Shrinks rather than wraps or overflows at a large text
              // scale, so the target stays one readable number.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    _energyText(summary.total, unit),
                    key: const ValueKey('kcal-goal-summary-total'),
                    maxLines: 1,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimens.spacing12),
          if (hasGoalRow) ...[
            Text(
              l10n.kcalGoalInfoSummaryIncludedNote,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: Dimens.spacing4),
          ],
          Text(
            l10n.kcalGoalInfoActivityExplanation,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: Dimens.spacing4),
          Semantics(
            identifier: 'kcal-goal-summary-equation',
            child: TextButton.icon(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: AlignmentDirectional.centerStart,
              ),
              onPressed: () => _launchEquationSource(context),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(l10n.kcalGoalInfoSummaryEquationLink),
            ),
          ),
        ],
      ),
    );
  }

  String _termLabel(BuildContext context, KcalGoalSummaryTerm term) {
    final l10n = S.of(context);
    switch (term) {
      case KcalGoalSummaryTerm.maintenance:
        return l10n.kcalGoalInfoSummaryMaintenanceRow;
      case KcalGoalSummaryTerm.weightGoal:
        return l10n.kcalGoalInfoSummaryGoalRow(breakdown.goal.getName(context));
      case KcalGoalSummaryTerm.manualAdjustment:
        return l10n.settingsKcalAdjustmentLabel;
      case KcalGoalSummaryTerm.activities:
        return l10n.kcalGoalInfoSummaryActivitiesRow;
    }
  }

  /// Opens the IOM 2005 report the Sources screen cites for the TDEE.
  Future<void> _launchEquationSource(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorText = S.of(context).errorOpeningBrowser;
    if (await tryLaunchExternalUrl(URLConst.sourceEnergyIomDriURL)) return;
    messenger.showSnackBar(SnackBar(content: Text(errorText)));
  }
}

/// How the calorie goal splits into carb / fat / protein gram targets.
class _MacroCard extends StatelessWidget {
  final KcalGoalBreakdownEntity breakdown;

  const _MacroCard({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final goalKcal = breakdown.totalKcalGoal.round();
    return _SectionCard(
      title: l10n.kcalGoalInfoMacroSection,
      children: [
        Text(
          l10n.kcalGoalInfoMacroExplanation,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: Dimens.spacing12),
        _FormulaText.raw(
          text: '${l10n.carbsLabel}: '
              '${_macroLine(goalKcal, breakdown.carbsFractionGoal, MacroCalc.carbsKcalPerGram, breakdown.carbsGoalGrams)}\n'
              '${l10n.fatLabel}: '
              '${_macroLine(goalKcal, breakdown.fatsFractionGoal, MacroCalc.fatKcalPerGram, breakdown.fatsGoalGrams)}\n'
              '${l10n.proteinLabel}: '
              '${_macroLine(goalKcal, breakdown.proteinsFractionGoal, MacroCalc.proteinKcalPerGram, breakdown.proteinsGoalGrams)}',
        ),
        const Divider(height: Dimens.spacing20),
        _ValueRow(
          label: l10n.carbsLabel,
          value: '${breakdown.carbsGoalGrams.toInt()} g',
          emphasized: true,
        ),
        _ValueRow(
          label: l10n.fatLabel,
          value: '${breakdown.fatsGoalGrams.toInt()} g',
          emphasized: true,
        ),
        _ValueRow(
          label: l10n.proteinLabel,
          value: '${breakdown.proteinsGoalGrams.toInt()} g',
          emphasized: true,
        ),
      ],
    );
  }

  /// One substituted line of the gram computation, e.g.
  /// `2100 × 60 % ÷ 4 = 315 g`. Percentages are shown rounded the way the
  /// macro-split dialog edits them; the gram result comes from the entity,
  /// not from re-deriving it here.
  String _macroLine(
    int goalKcal,
    double fraction,
    double kcalPerGram,
    double grams,
  ) {
    final pct = (fraction * 100).round();
    final density = kcalPerGram.toStringAsFixed(0);
    // Grams truncate (not round) to match the dashboard's macro tiles.
    return '$goalKcal × $pct % ÷ $density = ${grams.toInt()} g';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(Dimens.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Dimens.spacing12),
          ...children,
        ],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;
  final Key? valueKey;

  const _ValueRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.valueKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle = emphasized
        ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)
        : theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimens.spacing4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: Dimens.spacing8),
          // Flexible so a long value at a large text scale wraps instead
          // of pushing the row past the card edge.
          Flexible(
            child: Text(
              value,
              key: valueKey,
              style: valueStyle,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormulaSideLabel extends StatelessWidget {
  final String text;

  const _FormulaSideLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimens.spacing4),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

/// The substituted equation, rendered monospace. Formula constants are
/// defined in kcal by the IOM source, so the equation line always reads
/// kcal even when the display unit is kJ — the converted result appears in
/// the summary rows instead.
class _FormulaText extends StatelessWidget {
  final String? formula;
  final double? resultKcal;
  final String? rawText;

  const _FormulaText({required this.formula, required this.resultKcal})
      : rawText = null;

  /// Renders pre-assembled monospace lines (used by the macro card, whose
  /// per-line results are grams rather than a single kcal value).
  const _FormulaText.raw({required String text})
      : rawText = text,
        formula = null,
        resultKcal = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = rawText ??
        '$formula\n= ${resultKcal!.round()} ${S.of(context).kcalLabel}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimens.spacing8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Dimens.spacing8),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
      ),
    );
  }
}

/// Formats a stored kcal component with an explicit sign in the current
/// display unit, so additions and subtractions in the breakdown read as
/// such ("+300 kcal", "−500 kcal").
String _signedEnergy(BuildContext context, double kcal) {
  final formatted = EnergyDisplay.formatWithUnit(context, kcal.abs());
  if (kcal < 0) return '−$formatted';
  return '+$formatted';
}

/// A whole display-unit value from [KcalGoalBreakdownEntity.summary], with
/// the same minus sign the signed rows use.
String _energyText(int value, String unit) =>
    value < 0 ? '−${-value} $unit' : '$value $unit';

String _signedEnergyText(int value, String unit) =>
    value < 0 ? '−${-value} $unit' : '+$value $unit';
