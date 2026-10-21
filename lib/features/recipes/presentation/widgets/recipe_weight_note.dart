import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The line under the builder's weight field (#55): the ingredients' raw
/// weight, and while a weight after cooking is set ([overridden]) both of
/// them and a button that goes back to the raw sum. Weights show whole
/// grams, or one decimal where that tells them apart.
class RecipeWeightNote extends StatelessWidget {
  final double rawWeightG;
  final double cookedWeightG;
  final bool overridden;
  final VoidCallback onReset;

  const RecipeWeightNote({
    super.key,
    required this.rawWeightG,
    required this.cookedWeightG,
    required this.overridden,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final palette = theme.brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
    final style = theme.textTheme.bodySmall?.copyWith(color: palette.textMuted);
    String grams(double value) {
      final rounded = double.parse(value.toStringAsFixed(1));
      return rounded == rounded.roundToDouble()
          ? rounded.toStringAsFixed(0)
          : rounded.toStringAsFixed(1);
    }

    final raw = grams(rawWeightG);
    if (!overridden) {
      return Text(s.recipeRawWeightLabel(raw), style: style);
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Dimens.spacing8,
      children: [
        Text(
          s.recipeRawAndCookedWeightLabel(raw, grams(cookedWeightG)),
          style: style,
        ),
        TextButton(
          onPressed: onReset,
          child: Text(s.recipeUseIngredientSumLabel),
        ),
      ],
    );
  }
}
