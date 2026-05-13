import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/sources_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

class DisclaimerDialog extends StatelessWidget {
  const DisclaimerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).settingsDisclaimerLabel),
      content: Text(S.of(context).disclaimerText),
      actions: [
        TextButton.icon(
          onPressed: () {
            Navigator.of(context).pop(true);
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SourcesScreen()),
            );
          },
          icon: const Icon(Icons.menu_book_outlined),
          label: Text(S.of(context).settingsSourcesLabel),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: Text(S.of(context).dialogOKLabel),
        ),
      ],
    );
  }
}
