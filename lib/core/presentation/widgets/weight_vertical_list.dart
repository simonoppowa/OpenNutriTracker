import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_weight/presentation/add_weight_screen.dart';

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
            Icon(Icons.monitor_weight_outlined,
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
                return Align(
                  alignment: Alignment.topLeft,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16, // Add empty SizeBox for the (left) padding
                      ),
                      SizedBox(
                        width: 125,
                        height: 120,
                        child: Card(
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: InkWell(
                            onTap: () =>
                                _onPlaceholderCardTapped(context, weight),
                            // Icons.keyboard_arrow_down
                            // Icons.keyboard_arrow_up
                            child: Icon(Icons.add,
                                size: 36,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.5)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }))
    ]);
  }

  void _onPlaceholderCardTapped(BuildContext context, double weightDaily) {
    Navigator.of(context).pushNamed(NavigationOptions.addWeightRoute,
        arguments: AddWeightScreenArguments(day: day, weight: weightDaily));
  }
}
