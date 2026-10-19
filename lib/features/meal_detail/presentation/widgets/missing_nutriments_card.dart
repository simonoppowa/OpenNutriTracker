import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// A hint in the meal detail of a scanned product that Open Food Facts
/// knows without nutrition values (see `lacksNutrients`), offering to read
/// them off the pack's nutrition table.
class MissingNutrimentsCard extends StatelessWidget {
  final VoidCallback onScan;

  const MissingNutrimentsCard({super.key, required this.onScan});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      identifier: 'meal-detail-missing-nutrients',
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
                    Icons.document_scanner_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: Dimens.spacing12),
                  Expanded(
                    child: Text(
                      l10n.labelScanMissingTitle,
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
                l10n.labelScanMissingBody,
                style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Semantics(
                  identifier: 'meal-detail-missing-nutrients-scan',
                  child: TextButton(
                    onPressed: onScan,
                    child: Text(l10n.labelScanAction),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
