import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/generated/l10n.dart';

class OffDisclaimer extends StatelessWidget {
  const OffDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    return Text(
      S.of(context).offDisclaimer,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: palette.textMuted,
            fontStyle: FontStyle.italic,
          ),
    );
  }
}
