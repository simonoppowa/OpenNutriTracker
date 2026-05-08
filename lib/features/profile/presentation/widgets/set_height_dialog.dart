import 'package:flutter/material.dart';
import 'package:horizontal_picker/horizontal_picker.dart';
import 'package:opennutritracker/features/profile/presentation/utils/profile_picker_bounds.dart';
import 'package:opennutritracker/generated/l10n.dart';

class SetHeightDialog extends StatefulWidget {
  final double userHeight;
  final bool usesImperialUnits;

  const SetHeightDialog({
    super.key,
    required this.userHeight,
    required this.usesImperialUnits,
  });

  @override
  State<SetHeightDialog> createState() => _SetHeightDialogState();
}

class _SetHeightDialogState extends State<SetHeightDialog> {
  late double selectedHeight;

  @override
  void initState() {
    super.initState();
    selectedHeight = widget.userHeight;
  }

  @override
  Widget build(BuildContext context) {
    final minHeight =
        minSelectableHeight(widget.userHeight, widget.usesImperialUnits);
    final maxHeight =
        maxSelectableHeight(widget.userHeight, widget.usesImperialUnits);


    return AlertDialog(
      title: Text(S.of(context).selectHeightDialogLabel),
      content: Wrap(
        children: [
          Column(
            children: [
              HorizontalPicker(
                height: 100,
                backgroundColor: Colors.transparent,
                minValue: minHeight,
                maxValue: maxHeight,
                divisions: 400,
                suffix: widget.usesImperialUnits
                    ? S.of(context).ftLabel
                    : S.of(context).cmLabel,
                onChanged: (value) {
                  setState(() {
                    selectedHeight = value;
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
          onPressed: () {
            final hardMax = absoluteMaxHeight(widget.usesImperialUnits);
            Navigator.pop(context, selectedHeight.clamp(minHeight, hardMax));
          },
          child: Text(S.of(context).dialogOKLabel),
        ),
      ],
    );
  }
}
