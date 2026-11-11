import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/log_tray.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// A new custom meal carrying [barcode], so the next scan of it finds the
/// user's own entry.
MealEntity missingProductMeal(String barcode) {
  final empty = MealEntity.empty();
  return MealEntity(
    code: barcode,
    name: empty.name,
    url: empty.url,
    mealQuantity: empty.mealQuantity,
    mealUnit: empty.mealUnit,
    servingQuantity: empty.servingQuantity,
    servingUnit: empty.servingUnit,
    servingSize: empty.servingSize,
    nutriments: empty.nutriments,
    source: MealSourceEntity.custom,
  );
}

/// Under the scanner's "Product not found": opens a new custom meal with the
/// barcode no database knew, in place of the scanner. Its values are typed
/// from the label, or read off it with a photo where AI meal assistance is
/// on.
class AddMissingProductButton extends StatelessWidget {
  final String barcode;
  final IntakeTypeEntity intakeType;
  final DateTime day;
  final LogTray? logTray;

  const AddMissingProductButton({
    super.key,
    required this.barcode,
    required this.intakeType,
    required this.day,
    this.logTray,
  });

  Future<void> _open(BuildContext context) async {
    final config = await locator<GetConfigUsecase>().getConfig();
    if (!context.mounted) return;
    await Navigator.of(context).pushReplacementNamed(
      NavigationOptions.editMealRoute,
      arguments: EditMealScreenArguments(
        day,
        missingProductMeal(barcode),
        intakeType,
        config.usesImperialFoodUnits,
        logTray: logTray,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
    child: Column(
      children: [
        Semantics(
          identifier: 'scanner-add-missing-product',
          child: OutlinedButton.icon(
            icon: const Icon(Icons.document_scanner_outlined),
            label: Text(S.of(context).scannerAddFromLabelButton),
            onPressed: () => _open(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          S.of(context).scannerAddFromLabelHint(barcode),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}
