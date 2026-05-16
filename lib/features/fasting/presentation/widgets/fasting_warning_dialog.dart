import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

/// One-time content warning shown before the fasting timer becomes usable.
///
/// Returns `true` when the user accepts and `false` (or null on barrier
/// dismissal — though the dialog is non-dismissible by default) when they
/// decline. The caller is responsible for routing back when declined and for
/// persisting the acknowledgement when accepted.
class FastingWarningDialog extends StatelessWidget {
  static const _beatUrl = 'https://www.beateatingdisorders.org.uk/';
  static const _nedaUrl = 'https://www.nationaleatingdisorders.org/';

  const FastingWarningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(l10n.fastingWarningTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.fastingWarningBody, style: textTheme.bodyMedium),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: l10n.fastingLinkBeat,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.primary,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _open(_beatUrl),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: l10n.fastingLinkNeda,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.primary,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _open(_nedaUrl),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Semantics(
          identifier: 'fasting-warning-decline',
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.fastingWarningDecline),
          ),
        ),
        Semantics(
          identifier: 'fasting-warning-accept',
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.fastingWarningAccept),
          ),
        ),
      ],
    );
  }

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
