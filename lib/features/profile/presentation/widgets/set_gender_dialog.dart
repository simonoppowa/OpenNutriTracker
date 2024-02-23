import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

class SetGenderDialog extends StatelessWidget {
  const SetGenderDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(S.of(context).selectGenderDialogLabel),
      children: [
        SimpleDialogOption(
          child: Text(S.of(context).genderMaleLabel),
          onPressed: () {
            Navigator.pop(context, UserGenderEntity.male);
          },
        ),
        SimpleDialogOption(
          child: Text(S.of(context).genderFemaleLabel),
          onPressed: () {
            Navigator.pop(context, UserGenderEntity.female);
          },
        )
      ],
    );
  }
}
