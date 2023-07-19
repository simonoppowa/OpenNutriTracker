import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

class MealTitleExpanded extends StatelessWidget {
  final MealEntity meal;

  const MealTitleExpanded({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AutoSizeText.rich(
                minFontSize: 6,
                maxFontSize: 16,
                TextSpan(
                    text: meal.name ?? '',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground),
                    children: [
                      TextSpan(
                          text: ' ${meal.brands ?? ''}',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onBackground
                                  .withOpacity(0.7)))
                    ]),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            meal.mealQuantity != null
                ? Center(
                    child: Text(
                        '${meal.mealQuantity ?? ""} ${meal.mealUnit ?? ""} ',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onBackground
                                .withOpacity(0.8))),
                  )
                : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
