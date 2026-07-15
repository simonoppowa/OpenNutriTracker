import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/user_bmi_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/info_dialog.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/core/presentation/sources_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

class BMIOverview extends StatelessWidget {
  final double bmiValue;
  final UserNutritionalStatus nutritionalStatus;

  const BMIOverview({
    super.key,
    required this.bmiValue,
    required this.nutritionalStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final ringColor = _ringColor(context, palette);
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(Dimens.spacing32),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ringColor.withValues(alpha: isDark ? 0.22 : 0.16),
            border: Border.all(
              color: ringColor.withValues(alpha: 0.45),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${bmiValue.roundToPrecision(1)}',
                style: text.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: palette.textStrong,
                ),
              ),
              Text(
                S.of(context).bmiLabel,
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Dimens.spacing16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              nutritionalStatus.getName(context),
              style: text.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.textStrong,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(width: Dimens.spacing4),
            InkWell(
              borderRadius: Dimens.borderRadiusS,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => InfoDialog(
                    title: S.of(context).bmiLabel,
                    body: S.of(context).bmiInfo,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(Dimens.spacing4),
                child: Icon(
                  Icons.help_outline_rounded,
                  size: 22,
                  color: palette.textMuted,
                ),
              ),
            ),
            InkWell(
              borderRadius: Dimens.borderRadiusS,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SourcesScreen(),
                ),
              ),
              child: Tooltip(
                message: S.of(context).sourcesIconTooltip,
                child: Padding(
                  padding: const EdgeInsets.all(Dimens.spacing4),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 22,
                    color: palette.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
        Text(
          S.of(context).nutritionalStatusRiskLabel(
                nutritionalStatus.getRiskStatus(context),
              ),
          style: text.titleMedium?.copyWith(color: palette.textMuted),
        ),
      ],
    );
  }

  /// The single colour the BMI ring and its border lean on. A healthy reading
  /// rests on the active accent (so it follows the picker / Material You); the
  /// rest of the scale shades toward the theme's error colour as risk climbs,
  /// matching the rest of the calm-flat surfaces rather than Material's
  /// container roles.
  Color _ringColor(BuildContext context, AppPalette palette) {
    final scheme = Theme.of(context).colorScheme;
    switch (nutritionalStatus) {
      case UserNutritionalStatus.normalWeight:
        return scheme.primary;
      case UserNutritionalStatus.underWeight:
      case UserNutritionalStatus.preObesity:
      case UserNutritionalStatus.obesityClassI:
      case UserNutritionalStatus.obesityClassII:
      case UserNutritionalStatus.obesityClassIII:
        return scheme.error;
    }
  }
}
