import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/disclaimer_dialog.dart';
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
    final colors = Theme.of(context).colorScheme;
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
      child: Card(
        margin: margin,
        color: colors.tertiaryContainer,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: colors.onTertiaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.lowKcalWarningTitle,
                      style: textTheme.titleSmall?.copyWith(
                        color: colors.onTertiaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.lowKcalWarningBody(thresholdKcal.round()),
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onTertiaryContainer,
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
