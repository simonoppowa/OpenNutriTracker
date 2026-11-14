import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Asks before a food leaves the add-meal Recently list (#1198). Pops `true`
/// to remove it; anything else keeps it.
class RemoveFromRecentDialog extends StatelessWidget {
  const RemoveFromRecentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).recentRemoveDialogTitle),
      content: Text(S.of(context).recentRemoveDialogContent),
      actions: [
        Semantics(
          identifier: 'recent-remove-cancel',
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.of(context).dialogCancelLabel),
          ),
        ),
        Semantics(
          identifier: 'recent-remove-confirm',
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(S.of(context).recentRemoveConfirmLabel),
          ),
        ),
      ],
    );
  }
}
