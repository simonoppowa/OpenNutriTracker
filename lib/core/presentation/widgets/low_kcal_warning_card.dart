import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/presentation/widgets/disclaimer_dialog.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// A soft, non-blocking informational card surfaced near the daily kcal
/// target whenever the computed goal drops below the research-backed
/// floor for the user's calorie profile. It never prevents navigation,
/// never edits the goal, and never gates a save — it simply names the
/// floor and offers a quick link to the existing disclaimer + sources.
///
/// Visibility is decided by the caller (typically with
/// `CalorieGoalCalc.isBelowRecommendedDailyKcalFloor`); this widget only
/// renders, it does not compute.
class LowKcalWarningCard extends StatelessWidget {
  final double thresholdKcal;
  final EdgeInsetsGeometry margin;

  const LowKcalWarningCard({
    super.key,
    required this.thresholdKcal,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final accent = Theme.of(context).colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;
    // The card is found by text drivers via the "View disclaimer"
    // content-desc rather than by coordinate, because Semantics inside
    // a layout-greedy parent (ListView, Stack > Column) inherits the
    // parent's bounds even with `container: true`. See CLAUDE.md
    // "The `container: true` gotcha"; the identifier is kept for
    // future hierarchy queries.
    return Semantics(
      identifier: 'low-kcal-warning-card',
      container: true,
      child: Padding(
        padding: margin,
        child: AppCard(
          color: palette.surfaceMuted,
          padding: const EdgeInsets.fromLTRB(Dimens.spacing16, Dimens.spacing16, Dimens.spacing12, Dimens.spacing8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: accent, size: 22),
                  const SizedBox(width: Dimens.spacing12),
                  Expanded(
                    child: Text(
                      l10n.lowKcalWarningTitle,
                      style: textTheme.titleSmall?.copyWith(
                        color: palette.textStrong,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimens.spacing8),
              Text(
                l10n.lowKcalWarningBody(thresholdKcal.round()),
                style: textTheme.bodyMedium?.copyWith(
                  color: palette.textMuted,
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => _openDisclaimer(context),
                  child: Text(l10n.lowKcalWarningViewDisclaimer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDisclaimer(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const DisclaimerDialog(),
    );
  }
}
