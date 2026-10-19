import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/energy_plausibility.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// A hint in the meal detail when the per-100 g values of a product do not
/// add up (see [checkEnergyPlausibility]), with a way to correct them.
/// Renders nothing for plausible values or once the user chose to use them
/// anyway. [onScan], when given, offers to read the values off the pack's
/// nutrition table instead.
class NutrimentsPlausibilityCard extends StatefulWidget {
  final MealNutrimentsEntity nutriments;
  final VoidCallback onCorrect;
  final VoidCallback? onScan;

  const NutrimentsPlausibilityCard({
    super.key,
    required this.nutriments,
    required this.onCorrect,
    this.onScan,
  });

  @override
  State<NutrimentsPlausibilityCard> createState() =>
      _NutrimentsPlausibilityCardState();
}

class _NutrimentsPlausibilityCardState
    extends State<NutrimentsPlausibilityCard> {
  bool _kept = false;

  @override
  Widget build(BuildContext context) {
    final issue = checkEnergyPlausibility(widget.nutriments);
    if (issue == null || _kept) return const SizedBox.shrink();
    final l10n = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final textTheme = Theme.of(context).textTheme;
    final stated = issue.statedKcal;
    final expected = issue.expectedKcal;
    final body = stated != null && expected != null
        ? l10n.plausibilityEnergyBody(stated.round(), expected.round())
        : l10n.plausibilityUnclearBody;

    return Semantics(
      identifier: 'meal-detail-plausibility',
      container: true,
      child: Padding(
        padding: const EdgeInsets.only(top: Dimens.spacing16),
        child: AppCard(
          color: palette.surfaceMuted,
          padding: const EdgeInsets.fromLTRB(
            Dimens.spacing16,
            Dimens.spacing12,
            Dimens.spacing8,
            Dimens.spacing4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.report_problem_outlined,
                    color: Theme.of(context).colorScheme.error,
                    size: 22,
                  ),
                  const SizedBox(width: Dimens.spacing12),
                  Expanded(
                    child: Text(
                      l10n.plausibilityTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: palette.textStrong,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimens.spacing8),
              Text(
                body,
                style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
              ),
              Wrap(
                alignment: WrapAlignment.end,
                children: [
                  Semantics(
                    identifier: 'meal-detail-plausibility-keep',
                    child: TextButton(
                      onPressed: () => setState(() => _kept = true),
                      child: Text(l10n.plausibilityKeepAction),
                    ),
                  ),
                  if (widget.onScan != null)
                    Semantics(
                      identifier: 'meal-detail-plausibility-scan',
                      child: TextButton(
                        onPressed: widget.onScan,
                        child: Text(l10n.labelScanAction),
                      ),
                    ),
                  Semantics(
                    identifier: 'meal-detail-plausibility-correct',
                    child: TextButton(
                      onPressed: widget.onCorrect,
                      child: Text(l10n.plausibilityCorrectAction),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
