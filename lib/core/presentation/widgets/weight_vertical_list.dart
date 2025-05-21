import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_weight/presentation/add_weight_screen.dart';
import 'package:opennutritracker/core/presentation/widgets/placeholder_card.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';

class WeightVerticalList extends StatelessWidget {
  final DateTime day;
  final String title;
  final double weight;

  const WeightVerticalList(
      {super.key,
      required this.day,
      required this.title,
      required this.weight});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Icon(UserWeightEntity.getIconData(),
                size: 24, color: Theme.of(context).colorScheme.onSurface),
            const SizedBox(width: 4.0),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
          ],
        ),
      ),
      SizedBox(
        height: 160,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 1,
          itemBuilder: (BuildContext context, int index) {
            return PlaceholderCard(
                day: day,
                onTap: () => _onPlaceholderCardTapped(context),
                firstListElement: false);
          },
        ),
      )
    ]);
  }

  void _onPlaceholderCardTapped(BuildContext context) {
    Navigator.of(context).pushNamed(NavigationOptions.addWeightRoute,
        arguments: AddWeightScreenArguments(day: day));
  }
}
