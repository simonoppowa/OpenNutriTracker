import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/features/home/presentation/widgets/log_water_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// #32: hydration chip that sits next to the weight chip on the home
/// screen. Reads `waterMlToday` and `waterGoalMl` from `HomeLoadedState`
/// so it stays consistent with whatever logical day the rest of the
/// home view is using.
class QuickWaterWidget extends StatelessWidget {
  final int waterMlToday;
  final int waterGoalMl;

  const QuickWaterWidget({
    super.key,
    required this.waterMlToday,
    required this.waterGoalMl,
  });

  @override
  Widget build(BuildContext context) {
    final label = S.of(context).waterChipLabel(waterMlToday, waterGoalMl);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final accent = Theme.of(context).colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      identifier: 'home-water-chip',
      child: Material(
        color: Colors.transparent,
        borderRadius: Dimens.borderRadiusM,
        child: InkWell(
          borderRadius: Dimens.borderRadiusM,
          onTap: () => _showDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimens.spacing12,
              vertical: Dimens.spacing8,
            ),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: Dimens.borderRadiusM,
              border: Border.all(color: palette.border, width: Dimens.hairline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.water_drop_rounded, size: 18, color: palette.protein),
                const SizedBox(width: Dimens.spacing8),
                Text(
                  label,
                  style: textTheme.labelLarge?.copyWith(
                    color: palette.textStrong,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: Dimens.spacing4),
                Semantics(
                  identifier: 'home-water-edit',
                  container: true,
                  child: Icon(Icons.add_rounded, size: 18, color: accent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const LogWaterDialog(),
    );
  }
}
