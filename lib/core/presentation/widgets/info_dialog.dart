import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class InfoDialog extends StatelessWidget {
  const InfoDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).bmiLabel),
      icon: const Icon(Icons.help_outline_outlined),
      content: Text(S.of(context).bmiInfo),
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
