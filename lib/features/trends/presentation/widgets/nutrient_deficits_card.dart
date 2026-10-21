import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/nutrient_panel_rows.dart';
import 'package:opennutritracker/features/trends/domain/deficit_threshold_setting.dart';
import 'package:opennutritracker/features/trends/domain/nutrient_deficits.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The micronutrients that most often fell short of their reference in the
/// period (#59), each with the share of the judged days, and the threshold
/// the user can change here.
class NutrientDeficitsCard extends StatelessWidget {
  final List<NutrientDeficit> deficits;
  final int thresholdPercent;
  final ValueChanged<int> onThresholdChanged;

  const NutrientDeficitsCard({
    super.key,
    required this.deficits,
    required this.thresholdPercent,
    required this.onThresholdChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final palette = theme.brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
    final rows = {for (final row in NutrientPanelRow.all) row.key: row};

    return AppCard(
      padding: const EdgeInsets.all(Dimens.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.trendsDeficitsTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Semantics(
                identifier: 'trends-deficit-threshold',
                child: PopupMenuButton<int>(
                  initialValue: thresholdPercent,
                  onSelected: onThresholdChanged,
                  itemBuilder: (_) => [
                    for (final percent in DeficitThresholdSetting.choices)
                      PopupMenuItem(
                        value: percent,
                        child: Text(s.trendsDeficitThresholdLabel(percent)),
                      ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: Dimens.spacing4,
                    ),
                    child: Text(
                      s.trendsDeficitThresholdLabel(thresholdPercent),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimens.spacing12),
          if (deficits.isEmpty)
            Text(
              s.trendsNoDeficitsLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.textMuted,
              ),
            )
          else
            for (final deficit in deficits) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      rows[deficit.key]?.label(s) ?? deficit.key,
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                  Text(
                    s.trendsDaysOfLabel(
                      deficit.deficitDays,
                      deficit.evaluatedDays,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textStrong,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimens.spacing4),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: deficit.share,
                  minHeight: 6,
                  backgroundColor: palette.surfaceMuted,
                  valueColor: AlwaysStoppedAnimation(theme.colorScheme.error),
                ),
              ),
              const SizedBox(height: Dimens.spacing12),
            ],
          Text(
            s.trendsDeficitsHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
