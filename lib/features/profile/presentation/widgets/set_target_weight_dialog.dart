import 'package:flutter/material.dart';
import 'package:horizontal_picker/horizontal_picker.dart';
import 'package:opennutritracker/features/profile/presentation/utils/profile_picker_bounds.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Outcome of [SetTargetWeightDialog]. The dialog has three exits:
///
///   * Cancel — returns `null` from `showDialog`.
///   * OK with a value — returns a [TargetWeightDialogResult] with [value]
///     set and [clear] false. Caller persists the new target.
///   * Clear (only offered when a target is already set) — returns a result
///     with [clear] true and [value] null. Caller writes `null` back to the
///     user record.
///
/// Keeping clear separate from "OK with value" means a user who never wanted
/// a target in the first place isn't forced to commit to an arbitrary number
/// just to back out of the dialog.
class TargetWeightDialogResult {
  final double? value;
  final bool clear;

  const TargetWeightDialogResult.value(this.value) : clear = false;
  const TargetWeightDialogResult.cleared()
      : value = null,
        clear = true;
}

class SetTargetWeightDialog extends StatefulWidget {
  /// Pre-selected value the picker centres on. In display units (kg or lbs
  /// depending on [usesImperialUnits]). When the user has no existing
  /// target the caller typically seeds this from current weight, so the
  /// wheel doesn't dump them on a wildly distant number.
  final double initialTargetWeight;

  /// Whether the user already has a target set. Controls whether the
  /// "Clear target" action is offered alongside the OK / Cancel buttons.
  final bool hasExistingTarget;

  final bool usesImperialUnits;

  const SetTargetWeightDialog({
    super.key,
    required this.initialTargetWeight,
    required this.hasExistingTarget,
    required this.usesImperialUnits,
  });

  @override
  State<SetTargetWeightDialog> createState() => _SetTargetWeightDialogState();
}

class _SetTargetWeightDialogState extends State<SetTargetWeightDialog> {
  late double selectedWeight;

  @override
  void initState() {
    super.initState();
    selectedWeight = widget.initialTargetWeight;
  }

  @override
  Widget build(BuildContext context) {
    final minWeight =
        minSelectableWeight(widget.initialTargetWeight, widget.usesImperialUnits);
    final maxWeight =
        maxSelectableWeight(widget.initialTargetWeight, widget.usesImperialUnits);

    return AlertDialog(
      title: Text(S.of(context).profileTargetWeightLabel),
      content: Wrap(
        children: [
          Column(
            children: [
              HorizontalPicker(
                height: 100,
                backgroundColor: Colors.transparent,
                minValue: minWeight,
                maxValue: maxWeight,
                initialPosition: InitialPosition.center,
                divisions: 1000,
                suffix: widget.usesImperialUnits
                    ? S.of(context).lbsLabel
                    : S.of(context).kgLabel,
                onChanged: (value) {
                  setState(() {
                    selectedWeight = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      actions: <Widget>[
        if (widget.hasExistingTarget)
          TextButton(
            onPressed: () => Navigator.of(context).pop(
              const TargetWeightDialogResult.cleared(),
            ),
            child: Text(S.of(context).profileTargetWeightClearAction),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context).dialogCancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            TargetWeightDialogResult.value(
              clampWeightSelection(selectedWeight, minWeight),
            ),
          ),
          child: Text(S.of(context).dialogOKLabel),
        ),
      ],
    );
  }
}
