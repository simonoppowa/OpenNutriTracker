import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ErrorDialog extends StatelessWidget {
  final String errorText;
  final VoidCallback onRefreshPressed;

  const ErrorDialog({
    super.key,
    required this.errorText,
    required this.onRefreshPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 64, color: palette.textMuted),
          const SizedBox(height: Dimens.spacing16),
          Text(errorText, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Dimens.spacing16),
          FilledButton.icon(
            onPressed: () => onRefreshPressed(),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(S.of(context).retryLabel),
          ),
        ],
      ),
    );
  }
}
