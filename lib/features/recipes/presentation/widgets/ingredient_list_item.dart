import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/utils/energy_display.dart';

class IngredientListItem extends StatelessWidget {
  final RecipeIngredientEntity ingredient;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  const IngredientListItem({
    super.key,
    required this.ingredient,
    this.onEdit,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final meal = ingredient.snapshotMeal;
    final kcalPer100 = meal.nutriments.energyKcal100 ?? 0;
    final contributionKcal = kcalPer100 * ingredient.convertedAmountG / 100;
    final amountStr = ingredient.amount % 1 == 0
        ? ingredient.amount.toStringAsFixed(0)
        : ingredient.amount.toStringAsFixed(1);

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      title: Text(
        meal.name ?? '?',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '$amountStr ${ingredient.unit} · '
        '${EnergyDisplay.formatWithUnit(context, contributionKcal)}',
      ),
      onTap: onEdit,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: onRemove,
      ),
    );
  }
}
