import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class DeleteAllDialog extends StatelessWidget {
  const DeleteAllDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).deleteTimeDialogPluralTitle),
      content: Text(S.of(context).deleteTimeDialogPluralContent),
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
