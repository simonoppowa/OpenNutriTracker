import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_card.dart';
import 'package:opennutritracker/core/presentation/widgets/placeholder_card.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_screen.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';

class IntakeVerticalList extends StatelessWidget {
  final DateTime day;
  final String title;
  final IconData listIcon;
  final AddMealType addMealType;
  final List<IntakeEntity> intakeList;
  final Function(BuildContext, IntakeEntity) onItemLongPressedCallback;

  const IntakeVerticalList(
      {Key? key,
      required this.day,
      required this.title,
      required this.listIcon,
      required this.addMealType,
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
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: intakeList.length + 1, // List length + placeholder card
            itemBuilder: (BuildContext context, int index) {
              final firstListElement = index == 0 ? true : false;
              if (index == intakeList.length) {
                return PlaceholderCard(
                    day: day,
                    onTap: () => _onPlaceholderCardTapped(context),
                    firstListElement: firstListElement);
              } else {
                final intakeEntity = intakeList[index];
                return IntakeCard(
                    key: ValueKey(intakeEntity.meal.code),
                    intake: intakeEntity,
                    onItemLongPressed: onItemLongPressedCallback,
                    firstListElement: firstListElement);
              }
            },
          ),
        ),
      ],
    );
  }

  void _onPlaceholderCardTapped(BuildContext context) {
    Navigator.pushNamed(context, NavigationOptions.addMealRoute,
        arguments: AddMealScreenArguments(addMealType, day));
  }
}
