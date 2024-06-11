import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ChangeDialog extends StatelessWidget {
  final double amount;
  const ChangeDialog({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).deleteTimeDialogTitle),
      content: Text(S.of(context).deleteTimeDialogContent),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text(S.of(context).dialogOKLabel)),
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(S.of(context).dialogCancelLabel))
      ],
    );
  }
}
