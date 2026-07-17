import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/extensions.dart';

class MealDetailMacroNutrients extends StatelessWidget {
  final String typeString;
  final double? value;
  final Color? color;

  const MealDetailMacroNutrients({
    super.key,
    required this.typeString,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (color != null) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: Dimens.spacing8),
        ],
        Text(
          '${value?.roundToPrecision(1) ?? "?"} g',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: Dimens.spacing4),
        Text(
          typeString,
          style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
        ),
      ],
    );
  }
}
