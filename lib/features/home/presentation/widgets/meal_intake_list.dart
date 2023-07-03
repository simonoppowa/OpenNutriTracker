import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_card.dart';
import 'package:opennutritracker/core/presentation/widgets/placeholder_intake_card.dart';

class MealIntakeList extends StatelessWidget {
  final String title;
  final IconData listIcon;
  final List<IntakeEntity> intakeList;
  final Function(BuildContext, IntakeEntity) onItemLongPressedCallback;

  const MealIntakeList(
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
          padding: const EdgeInsets.fromLTRB(0.0, 16.0, 0.0, 8.0),
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        intakeList.isEmpty
            ? Align(
                alignment: Alignment.centerLeft,
                child: PlaceholderIntakeCard(
                  icon: listIcon,
                ))
            : SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: intakeList.length,
                  itemBuilder: (BuildContext context, int index) {
                    final intakeEntity = intakeList[index];
                    return IntakeCard(
                        key: ValueKey(intakeEntity.product.code),
                        intake: intakeEntity,
                        onItemLongPressed: onItemLongPressedCallback);
                  },
                ),
              ),
      ],
    );
  }
}
