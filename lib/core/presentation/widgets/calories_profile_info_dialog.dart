import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/calories_profile_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

class CaloriesProfileInfoDialog extends StatefulWidget {
  final CaloriesProfileEntity initialProfile;

  const CaloriesProfileInfoDialog({
    super.key,
    this.initialProfile = CaloriesProfileEntity.averaged,
  });

  @override
  State<CaloriesProfileInfoDialog> createState() =>
      _CaloriesProfileInfoDialogState();
}

class _CaloriesProfileInfoDialogState extends State<CaloriesProfileInfoDialog> {
  late CaloriesProfileEntity _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialProfile;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).caloriesProfileInfoTitle),
      icon: const Icon(Icons.tune_rounded),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).caloriesProfileInfoBody,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            // Use the per-tile groupValue/onChanged form rather than a
            // RadioGroup ancestor: the ancestor form does not always
            // propagate taps to RadioListTile children (the bug surfaced
            // here was that switching estrogen ↔ testosterone produced
            // no kcal change because OK kept returning the initial value).
            // The per-tile API is marked deprecated in newer SDKs, but it
            // is the only form that captures the selection reliably.
            // ignore: deprecated_member_use
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final profile in CaloriesProfileEntity.values)
                  // ignore: deprecated_member_use
                  RadioListTile<CaloriesProfileEntity>(
                    value: profile,
                    // ignore: deprecated_member_use
                    groupValue: _selected,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selected = value);
                      }
                    },
                    contentPadding: EdgeInsets.zero,
                    title: Text(profile.getName(context)),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context).dialogCancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text(S.of(context).dialogOKLabel),
        ),
      ],
    );
  }
}
