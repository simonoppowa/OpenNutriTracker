import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_activity/presentation/add_activity_screen.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_screen.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/meal_item_card.dart';
import 'package:opennutritracker/generated/l10n.dart';

class AddItemBottomSheet extends StatelessWidget {
  final DateTime day;
  final bool showActivityTracking;
  final bool usesImperialUnits;

  const AddItemBottomSheet({
    super.key,
    required this.day,
    this.showActivityTracking = true,
    this.usesImperialUnits = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                S.of(context).addItemLabel,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
            _buildRecentSection(context),
          if (showActivityTracking) ...[
            Semantics(
              identifier: 'add-item-activity',
              child: ListTile(
                title: Text(
                  S.of(context).activityLabel,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                subtitle: Text(
                  S.of(context).activityExample,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                ),
                // ignore: sized_box_for_whitespace
                leading: Container(
                  height: double.infinity,
                  child: Icon(
                    UserActivityEntity.getIconData(),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  _showAddActivityScreen(context);
                },
              ),
            ),
            const Divider(indent: 16, endIndent: 16),
          ],
          Semantics(
            identifier: 'add-item-breakfast',
            child: ListTile(
              title: Text(
                S.of(context).breakfastLabel,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              subtitle: Text(
                S.of(context).breakfastExample,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
              // ignore: sized_box_for_whitespace
              leading: Container(
                height: double.infinity,
                child: Icon(IntakeTypeEntity.breakfast.getIconData()),
              ),
              onTap: () {
                _showAddItemScreen(context, AddMealType.breakfastType);
              },
            ),
          ),
          Semantics(
            identifier: 'add-item-lunch',
            child: ListTile(
              title: Text(
                S.of(context).lunchLabel,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              subtitle: Text(
                S.of(context).lunchExample,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
              // ignore: sized_box_for_whitespace
              leading: Container(
                height: double.infinity,
                child: Icon(IntakeTypeEntity.lunch.getIconData()),
              ),
              onTap: () {
                _showAddItemScreen(context, AddMealType.lunchType);
              },
            ),
          ),
          Semantics(
            identifier: 'add-item-dinner',
            child: ListTile(
              title: Text(
                S.of(context).dinnerLabel,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              subtitle: Text(
                S.of(context).dinnerExample,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
              // ignore: sized_box_for_whitespace
              leading: Container(
                height: double.infinity,
                child: Icon(IntakeTypeEntity.dinner.getIconData()),
              ),
              onTap: () {
                _showAddItemScreen(context, AddMealType.dinnerType);
              },
            ),
          ),
          Semantics(
            identifier: 'add-item-snack',
            child: ListTile(
              title: Text(
                S.of(context).snackLabel,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              subtitle: Text(
                S.of(context).snackExample,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
              // ignore: sized_box_for_whitespace
              leading: Container(
                height: double.infinity,
                child: Icon(IntakeTypeEntity.snack.getIconData()),
              ),
              onTap: () {
                _showAddItemScreen(context, AddMealType.snackType);
              },
            ),
          ),
          const Divider(indent: 16, endIndent: 16),
          Semantics(
            identifier: 'add-item-recipes',
            child: ListTile(
              title: Text(
                S.of(context).recipesLabel,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              // ignore: sized_box_for_whitespace
              leading: Container(
                height: double.infinity,
                child: const Icon(Icons.menu_book_outlined),
              ),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(NavigationOptions.recipesRoute);
              },
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildRecentSection(BuildContext context) {
    // Guard for widget tests / early startup where the use case isn't wired.
    if (!locator.isRegistered<GetIntakeUsecase>()) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<List<IntakeEntity>>(
      future: locator<GetIntakeUsecase>().getRecentIntake(),
      builder: (context, snapshot) {
        final intakes = snapshot.data;
        if (intakes == null || intakes.isEmpty) return const SizedBox.shrink();
        // getRecentIntake() already returns the most-recent *unique* foods
        // (the data source dedupes by meal), so take the first few for quick
        // re-logging. Tapping a card opens its detail pre-filled.
        final recent = intakes.take(4).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                S.of(context).recentlyAddedLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            for (final intake in recent)
              MealItemCard(
                day: day,
                mealEntity: intake.meal,
                addMealType: AddMealExtension.fromIntakeTypeEntity(intake.type),
                usesImperialUnits: usesImperialUnits,
              ),
            const Divider(indent: 16, endIndent: 16),
          ],
        );
      },
    );
  }

  void _showAddItemScreen(BuildContext context, AddMealType itemType) {
    Navigator.of(context).pop(); // Close bottom sheet
    Navigator.of(context).pushNamed(
      NavigationOptions.addMealRoute,
      arguments: AddMealScreenArguments(itemType, day),
    );
  }

  void _showAddActivityScreen(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(context).pushNamed(
      NavigationOptions.addActivityRoute,
      arguments: AddActivityScreenArguments(day: day),
    );
  }
}
