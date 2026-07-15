import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/calories_profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/kcal_goal_breakdown_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_breakdown_usecase.dart';
import 'package:opennutritracker/core/presentation/sources_screen.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/energy_display.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/url_const.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

/// Transparency screen: shows every variable and intermediate step behind
/// today's kcal goal, so the number on the home screen is fully auditable
/// in-app. The values come from [GetKcalGoalBreakdownUsecase], which runs
/// the exact production calculation — this screen only renders, it never
/// computes goal math of its own.
class KcalGoalInfoScreen extends StatefulWidget {
  const KcalGoalInfoScreen({super.key});

  @override
  State<KcalGoalInfoScreen> createState() => _KcalGoalInfoScreenState();
}

class _KcalGoalInfoScreenState extends State<KcalGoalInfoScreen> {
  late final Future<KcalGoalBreakdownEntity> _breakdown;

  @override
  void initState() {
    super.initState();
    _breakdown = locator<GetKcalGoalBreakdownUsecase>().getBreakdown();
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
              _ResultCard(breakdown: breakdown),
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
    final uri = Uri.parse(URLConst.wikiCalculationsURL);
    final l10n = S.of(context);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorOpeningBrowser)));
    }
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
          value: l10n.yearsLabel(breakdown.age.toString()),
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

  String _maleFormulaText(KcalGoalBreakdownEntity b) =>
      '864 − 9.72 × ${b.age} '
      '+ ${b.paMaleFormula!.toStringAsFixed(2)} × 14.2 × ${b.weightKG.toStringAsFixed(1)} '
      '+ 503 × ${(b.heightCM / 100).toStringAsFixed(2)}';

  String _femaleFormulaText(KcalGoalBreakdownEntity b) =>
      '387 − 7.31 × ${b.age} '
      '+ ${b.paFemaleFormula!.toStringAsFixed(2)} × 10.9 × ${b.weightKG.toStringAsFixed(1)} '
      '+ 660.7 × ${(b.heightCM / 100).toStringAsFixed(2)}';
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

/// The final sum, mirroring the goal shown on the home screen.
class _ResultCard extends StatelessWidget {
  final KcalGoalBreakdownEntity breakdown;

  const _ResultCard({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);
    return _SectionCard(
      title: l10n.kcalGoalInfoResultSection,
      children: [
        _ValueRow(
          label: l10n.kcalGoalInfoTdeeResultLabel,
          value: EnergyDisplay.formatWithUnit(context, breakdown.tdeeKcal),
        ),
        _ValueRow(
          label: l10n.kcalGoalInfoAppliedAdjustmentLabel,
          value: _signedEnergy(context, breakdown.effectiveAdjustmentKcal),
        ),
        _ValueRow(
          label: l10n.settingsKcalAdjustmentLabel,
          value: _signedEnergy(context, breakdown.manualKcalAdjustment),
        ),
        _ValueRow(
          label: l10n.activityLabel,
          value: _signedEnergy(context, breakdown.activityKcal),
        ),
        const Divider(height: Dimens.spacing20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n.kcalGoalInfoResultSection,
                style: theme.textTheme.titleMedium,
              ),
            ),
            Text(
              EnergyDisplay.formatWithUnit(context, breakdown.totalKcalGoal),
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
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

  const _ValueRow({
    required this.label,
    required this.value,
    this.emphasized = false,
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
          Text(value, style: valueStyle),
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
  final String formula;
  final double resultKcal;

  const _FormulaText({required this.formula, required this.resultKcal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimens.spacing8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Dimens.spacing8),
      ),
      child: Text(
        '$formula\n= ${resultKcal.round()} ${S.of(context).kcalLabel}',
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
