import 'package:flutter/material.dart';
import 'package:horizontal_picker/horizontal_picker.dart';
import 'package:opennutritracker/core/utils/bounds/ranges_const.dart';
import 'package:opennutritracker/core/utils/bounds/validator.dart';
import 'package:opennutritracker/generated/l10n.dart';

class SetWeightDialog extends StatelessWidget {
  static const divisionsPerLbs = 5;
  static const divisionsPerKg = 10;
  static const kgScrollBuffer = 2;
  static const lbsScrollBuffer = 5;

  final double userWeight;
  final bool usesImperialUnits;
  late final int divisions;
  late final double maxWeight, minWeight;


  SetWeightDialog(this.userWeight, this.usesImperialUnits, {super.key})
      {
        super.key;
        divisions = calculateDivisions();
      }

  int calculateDivisions(){
    getCloserBound();
    return usesImperialUnits
        ? ((maxWeight - minWeight) * divisionsPerLbs).round()
        : ((maxWeight - minWeight) * divisionsPerKg).round();
  }

  void getCloserBound(){
    double initialMaxWeight = usesImperialUnits ? Ranges.maxWeightInLbs : Ranges.maxWeight;
    double initialMinWeight = usesImperialUnits ? Ranges.minWeightInLbs : Ranges.minWeight;
    initialMinWeight = initialMinWeight - (usesImperialUnits ? lbsScrollBuffer : kgScrollBuffer);
    initialMaxWeight = initialMaxWeight + (usesImperialUnits ? lbsScrollBuffer : kgScrollBuffer);
    if(initialMaxWeight - userWeight > userWeight - initialMinWeight){
      print("sehr leicht");
      minWeight = initialMinWeight;
      maxWeight = userWeight + (userWeight - minWeight);
    }else{
      print("sehr schwer");
      maxWeight = initialMaxWeight;
      minWeight = userWeight - (maxWeight - userWeight);
    }
  }

  @override
  Widget build(BuildContext context) {
    double selectedWeight = userWeight;
    return AlertDialog(
      title: Text(S.of(context).selectWeightDialogLabel),
      content: Wrap(children: [
        Column(
          children: [
            HorizontalPicker(
                height: 100,
                backgroundColor: Colors.transparent,
                minValue: minWeight,
                maxValue: maxWeight,
                initialPosition: InitialPosition.center,
                divisions:  divisions,
                suffix: usesImperialUnits
                    ? S.of(context).lbsLabel
                    : S.of(context).kgLabel,
                onChanged: (value) {
                  selectedWeight = value;
                })
          ],
        )
      ]),
      actions: <Widget>[
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(S.of(context).dialogCancelLabel)),
        TextButton(
            onPressed: () {
              double? weight = ValueValidator.parseWeightInKg(selectedWeight, isImperial: usesImperialUnits);
              if(weight != null) Navigator.pop(context, weight);
              else ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(S.of(context).onboardingWrongWeightLabel)));
            },
            child: Text(S.of(context).dialogOKLabel)),
      ],
    );
  }
}
