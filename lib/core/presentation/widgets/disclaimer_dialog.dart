import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class DisclaimerDialog extends StatelessWidget {
  const DisclaimerDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).settingsDisclaimerLabel),
      content: Text(S.of(context).disclaimerText),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text(S.of(context).dialogOKLabel))
      ],
    );
  }
}
