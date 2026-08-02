import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class DisclaimerDialog extends StatelessWidget {
  const DisclaimerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).settingsDisclaimerLabel),
      content: Text(S.of(context).disclaimerText),
      actions: [
        // Not the shared OK label: dismissing this dialog records an
        // acknowledgement in ConfigEntity.hasAcceptedDisclaimer.
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: Text(S.of(context).disclaimerAcknowledgeLabel),
        ),
      ],
    );
  }
}
