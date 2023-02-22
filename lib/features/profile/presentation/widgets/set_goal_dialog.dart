import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

class SetWeightGoalDialog extends StatelessWidget {
  const SetWeightGoalDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(S.of(context).chooseWeightGoalLabel),
      children: [
        SimpleDialogOption(
          child: Text(S.of(context).goalLoseWeight),
          onPressed: () {
            Navigator.pop(context, UserWeightGoalEntity.loseWeight);
          },
        ),
        SimpleDialogOption(
          child: Text(S.of(context).goalMaintainWeight),
          onPressed: () {
            Navigator.pop(context, UserWeightGoalEntity.maintainWeight);
          },
        ),
        SimpleDialogOption(
          child: Text(S.of(context).goalGainWeight),
          onPressed: () {
            Navigator.pop(context, UserWeightGoalEntity.gainWeight);
          },
        ),
      ],
    );
  }
}
