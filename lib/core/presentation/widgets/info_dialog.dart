import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class InfoDialog extends StatelessWidget {
  final String title;
  final String body;

  const InfoDialog({Key? key, required this.title, required this.body})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      icon: const Icon(Icons.help_outline_outlined),
      content: Text(body),
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
