import 'package:flutter/material.dart';
import 'package:horizontal_picker/horizontal_picker.dart';
import 'package:opennutritracker/features/profile/presentation/utils/profile_picker_bounds.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/feet_inches_input.dart';
import 'package:opennutritracker/generated/l10n.dart';

class SetHeightDialog extends StatefulWidget {
  /// The user's current height in centimetres. All display and input are
  /// handled internally; callers always work in cm.
  final double userHeightCm;
  final bool usesImperialUnits;

  const SetHeightDialog({
    super.key,
    required this.userHeightCm,
    required this.usesImperialUnits,
  });

  @override
  State<SetHeightDialog> createState() => _SetHeightDialogState();
}

class _SetHeightDialogState extends State<SetHeightDialog> {
  // Centimetre picker selection (metric path).
  late double _pickerCm;
  // Feet + inches path reports cm directly; null when invalid/empty.
  double? _imperialCm;

  @override
  void initState() {
    super.initState();
    _pickerCm = widget.userHeightCm;
    _imperialCm = widget.userHeightCm;
  }

  void _submit() {
    if (widget.usesImperialUnits) {
      final cm = _imperialCm;
      if (cm == null) {
        Navigator.of(context).pop();
        return;
      }
      Navigator.pop(context, cm);
    } else {
      final minHeight = minSelectableHeight(widget.userHeightCm, false);
      final hardMax = absoluteMaxHeight(false);
      Navigator.pop(context, _pickerCm.clamp(minHeight, hardMax));
    }
  }

  @override
  Widget build(BuildContext context) {
    final minHeight = minSelectableHeight(widget.userHeightCm, false);
    final maxHeight = maxSelectableHeight(widget.userHeightCm, false);

    return AlertDialog(
      title: Text(S.of(context).selectHeightDialogLabel),
      content: Wrap(
        children: [
          Column(
            children: [
              if (widget.usesImperialUnits)
                FeetInchesInput(
                  initialCm: widget.userHeightCm,
                  identifierPrefix: 'set-height-dialog',
                  autofocus: true,
                  onChangedCm: (cm) => setState(() => _imperialCm = cm),
                )
              else
                HorizontalPicker(
                  height: 100,
                  backgroundColor: Colors.transparent,
                  minValue: minHeight,
                  maxValue: maxHeight,
                  divisions: 400,
                  suffix: S.of(context).cmLabel,
                  onChanged: (value) {
                    setState(() {
                      _pickerCm = value;
                    });
                  },
                ),
            ],
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(S.of(context).dialogCancelLabel),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(S.of(context).dialogOKLabel),
        ),
      ],
    );
  }
}
