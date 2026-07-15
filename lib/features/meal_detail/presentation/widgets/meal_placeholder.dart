import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';

class MealPlaceholder extends StatelessWidget {
  const MealPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    return Container(
      height: 300,
      width: double.infinity,
      color: palette.surfaceMuted,
      child: Icon(
        Icons.restaurant_rounded,
        size: 48,
        color: palette.textMuted,
      ),
    );
  }
}
