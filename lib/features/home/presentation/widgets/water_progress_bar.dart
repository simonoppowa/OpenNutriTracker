import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Water drunk against the day's goal as a slim bar, for the calorie card
/// on Home and the diary's days (#31).
class WaterProgressBar extends StatelessWidget {
  final int currentMl;
  final int goalMl;
  final VoidCallback? onTap;

  const WaterProgressBar({
    super.key,
    required this.currentMl,
    required this.goalMl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final textTheme = Theme.of(context).textTheme;
    final progress = goalMl > 0 ? (currentMl / goalMl).clamp(0.0, 1.0) : 0.0;
    return Semantics(
      identifier: 'water-progress',
      button: onTap != null,
      child: InkWell(
        borderRadius: Dimens.borderRadiusM,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimens.spacing4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.water_drop_rounded,
                    size: 18,
                    color: palette.protein,
                  ),
                  const SizedBox(width: Dimens.spacing8),
                  Expanded(
                    child: Text(
                      S.of(context).waterChipLabel(currentMl, goalMl),
                      style: textTheme.labelLarge?.copyWith(
                        color: palette.textStrong,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: Dimens.spacing8),
              ClipRRect(
                borderRadius: Dimens.borderRadiusM,
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: palette.surfaceMuted,
                  color: palette.protein,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
