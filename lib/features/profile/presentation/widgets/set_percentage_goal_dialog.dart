import 'package:flutter/material.dart';
import 'package:horizontal_picker/horizontal_picker.dart';
import 'package:opennutritracker/generated/l10n.dart';

class SetPercentageDialog extends StatelessWidget {
  static const _rangePercent = 100.0;

  final double userPercentage;

  const SetPercentageDialog({super.key, required this.userPercentage});

  @override
  Widget build(BuildContext context) {
    double selectedPercentage = userPercentage*100;
    return AlertDialog(
      title: Text(S.of(context).selectPercentageDialogLabel),
      content: Wrap(
        children: [
          Column(
            children: [
              HorizontalPicker(
                  height: 100,
                  backgroundColor: Colors.transparent,
                  minValue: selectedPercentage - _rangePercent,
                  maxValue: selectedPercentage + _rangePercent,
                  divisions: 400,
                  suffix: ' ${S.of(context).cmLabel}',
                  onChanged: (value) {
                    selectedPercentage = value;
                  })
            ],
          )
        ],
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(S.of(context).dialogCancelLabel)),
        TextButton(
            onPressed: () {
              // TODO validate selected height
              Navigator.pop(context, selectedPercentage / 100);
            },
            child: Text(S.of(context).dialogOKLabel))
      ],
    );
  }
}
