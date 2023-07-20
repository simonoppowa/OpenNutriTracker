import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_card.dart';
import 'package:opennutritracker/core/presentation/widgets/placeholder_intake_card.dart';

class IntakeVerticalList extends StatelessWidget {
  final String title;
  final IconData listIcon;
  final List<IntakeEntity> intakeList;
  final Function(BuildContext, IntakeEntity) onItemLongPressedCallback;

  const IntakeVerticalList(
      {Key? key,
      required this.title,
      required this.listIcon,
      required this.intakeList,
      required this.onItemLongPressedCallback})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Icon(listIcon,
                  size: 24, color: Theme.of(context).colorScheme.onBackground),
              const SizedBox(width: 4.0),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground),
              ),
            ],
          ),
        ),
        intakeList.isEmpty
            ? Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PlaceholderIntakeCard(
                    icon: listIcon,
                  ),
                ))
            : SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: intakeList.length,
                  itemBuilder: (BuildContext context, int index) {
                    final intakeEntity = intakeList[index];
                    return IntakeCard(
                        key: ValueKey(intakeEntity.meal.code),
                        intake: intakeEntity,
                        onItemLongPressed: onItemLongPressedCallback,
                        firstListElement: index == 0 ? true : false);
                  },
                ),
              ),
      ],
    );
  }
}
