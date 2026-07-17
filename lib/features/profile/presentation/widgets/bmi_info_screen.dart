import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/user_bmi_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/presentation/sources_screen.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/calc/bmi_calc.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/url_const.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

/// Transparency screen for the BMI shown on the Profile tab: the inputs,
/// the formula with the user's numbers substituted in, and the full WHO
/// classification table with the user's own category highlighted. BMI and
/// status are computed through the same [BMICalc] calls the Profile bloc
/// uses, so this screen always matches the ring on the Profile tab.
class BmiInfoScreen extends StatefulWidget {
  /// Injectable for widget tests; production callers leave this null and
  /// get the locator-registered usecase.
  final GetUserUsecase? userUsecase;

  const BmiInfoScreen({super.key, this.userUsecase});

  @override
  State<BmiInfoScreen> createState() => _BmiInfoScreenState();
}

class _BmiInfoScreenState extends State<BmiInfoScreen> {
  late final Future<UserEntity> _user;

  @override
  void initState() {
    super.initState();
    _user = (widget.userUsecase ?? locator<GetUserUsecase>()).getUserData();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.bmiInfoScreenTitle)),
      body: FutureBuilder<UserEntity>(
        future: _user,
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final bmi = BMICalc.getBMI(user);
          final status = BMICalc.getNutritionalStatus(bmi);
          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimens.spacing16,
              vertical: Dimens.spacing16,
            ),
            children: [
              Text(
                l10n.bmiInfo,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: Dimens.spacing16),
              _SectionCard(
                title: l10n.kcalGoalInfoInputsSection,
                children: [
                  _ValueRow(
                    label: l10n.heightLabel,
                    value:
                        '${user.heightCM.toStringAsFixed(0)} ${l10n.cmLabel}',
                  ),
                  _ValueRow(
                    label: l10n.weightLabel,
                    value:
                        '${user.weightKG.toStringAsFixed(1)} ${l10n.kgLabel}',
                  ),
                ],
              ),
              const SizedBox(height: Dimens.spacing12),
              _SectionCard(
                title: l10n.bmiInfoFormulaSection,
                children: [
                  _FormulaBox(
                    text: 'BMI = ${l10n.weightLabel} (${l10n.kgLabel}) ÷ '
                        '(${l10n.heightLabel} (m))²\n'
                        '= ${user.weightKG.toStringAsFixed(1)} ÷ '
                        '${(user.heightCM / 100).toStringAsFixed(2)}²\n'
                        '= ${bmi.roundToPrecision(1)}',
                  ),
                  const Divider(height: Dimens.spacing20),
                  _ValueRow(
                    label: l10n.bmiLabel,
                    value: '${bmi.roundToPrecision(1)}',
                    emphasized: true,
                  ),
                ],
              ),
              const SizedBox(height: Dimens.spacing12),
              _SectionCard(
                title: l10n.bmiInfoClassificationSection,
                children: [
                  for (final row in _classificationRows(context))
                    _ClassificationRow(
                      row: row,
                      isUsers: row.status == status,
                    ),
                ],
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

  /// The WHO adult classification bands, matching [BMICalc]'s cut-offs.
  List<_Classification> _classificationRows(BuildContext context) {
    return [
      _Classification(UserNutritionalStatus.underWeight, '< 18.5'),
      _Classification(UserNutritionalStatus.normalWeight, '18.5 – 24.9'),
      _Classification(UserNutritionalStatus.preObesity, '25.0 – 29.9'),
      _Classification(UserNutritionalStatus.obesityClassI, '30.0 – 34.9'),
      _Classification(UserNutritionalStatus.obesityClassII, '35.0 – 39.9'),
      _Classification(UserNutritionalStatus.obesityClassIII, '≥ 40.0'),
    ];
  }

  Future<void> _launchWiki(BuildContext context) async {
    final uri = Uri.parse(URLConst.wikiCalculationsURL);
    final l10n = S.of(context);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorOpeningBrowser)),
      );
    }
  }
}

class _Classification {
  final UserNutritionalStatus status;
  final String range;

  const _Classification(this.status, this.range);
}

class _ClassificationRow extends StatelessWidget {
  final _Classification row;
  final bool isUsers;

  const _ClassificationRow({required this.row, required this.isUsers});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = isUsers
        ? theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          )
        : theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimens.spacing4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(row.status.getName(context), style: style)),
          const SizedBox(width: Dimens.spacing8),
          Text(row.range, style: style),
        ],
      ),
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

class _FormulaBox extends StatelessWidget {
  final String text;

  const _FormulaBox({required this.text});

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
        text,
        style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
      ),
    );
  }
}
