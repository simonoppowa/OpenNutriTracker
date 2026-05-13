import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/presentation/sources_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

class SetGenderDialog extends StatelessWidget {
  const SetGenderDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Row(
        children: [
          Expanded(
            child: Text(S.of(context).selectGenderDialogLabel),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: S.of(context).sourcesIconTooltip,
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SourcesScreen()),
            ),
          ),
        ],
      ),
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
        ),
        SimpleDialogOption(
          child: Text(S.of(context).genderNonBinaryLabel),
          onPressed: () {
            Navigator.pop(context, UserGenderEntity.nonBinary);
          },
        ),
      ],
    );
  }
}
