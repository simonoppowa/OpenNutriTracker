import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MealDetailBottomSheet extends StatelessWidget {
  final MealEntity product;
  final DateTime day;
  final IntakeTypeEntity intakeTypeEntity;
  final TextEditingController quantityTextController;
  final MealDetailBloc mealDetailBloc;

  final String selectedUnit;

  final Function(String?, String?) onQuantityOrUnitChanged;

  const MealDetailBottomSheet(
      {super.key,
      required this.product,
      required this.day,
      required this.intakeTypeEntity,
      required this.quantityTextController,
      required this.onQuantityOrUnitChanged,
      required this.mealDetailBloc,
      required this.selectedUnit});

  @override
  Widget build(BuildContext context) {
    final productMissingRequiredInfo = _hasRequiredProductInfoMissing();
    return BottomSheet(
        elevation: 10,
        onClosing: () {},
        enableDrag: false,
        builder: (context) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 0.5,
              ),
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Wrap(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              enabled: !productMissingRequiredInfo,
                              controller: quantityTextController
                                ..addListener(() {
                                  onQuantityOrUnitChanged(
                                      quantityTextController.text,
                                      selectedUnit);
                                }),
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+([.,]\d{0,2})?$'))
                              ],
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: S.of(context).quantityLabel,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                              child: DropdownButtonFormField(
                                  isExpanded: true,
                                  value: selectedUnit,
                                  decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      labelText: S.of(context).unitLabel),
                                  items: <DropdownMenuItem<String>>[
                                    if (product.hasServingValues)
                                      _getServingDropdownItem(context),
                                    if (product.isSolid ||
                                        !product.isLiquid && !product.isSolid)
                                      ..._getSolidUnitDropdownItems(context),
                                    if (product.isLiquid ||
                                        !product.isLiquid && !product.isSolid)
                                      ..._getLiquidUnitDropdownItems(context),
                                    ..._getOtherDropdownItems(context)
                                  ],
                                  onChanged: (value) {
                                    onQuantityOrUnitChanged(
                                        quantityTextController.text, value);
                                  }))
                        ],
                      ),
                      SizedBox(
                        width: double.infinity, // Make button full width
                        child: ElevatedButton.icon(
                            onPressed: !productMissingRequiredInfo
                                ? () {
                                    onAddButtonPressed(context);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                            ).copyWith(
                                elevation: ButtonStyleButton.allOrNull(0.0)),
                            icon: const Icon(Icons.add_outlined),
                            label: Text(S.of(context).addLabel)),
                      ),
                      productMissingRequiredInfo
                          ? Text(S.of(context).missingProductInfo,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.error))
                          : const SizedBox()
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }

  bool _hasRequiredProductInfoMissing() {
    final productNutriments = product.nutriments;
    if (productNutriments.energyKcal100 == null ||
        productNutriments.carbohydrates100 == null ||
        productNutriments.fat100 == null ||
        productNutriments.proteins100 == null) {
      return true;
    } else {
      return false;
    }
  }

  void onAddButtonPressed(BuildContext context) {
    mealDetailBloc.addIntake(
        context,
        mealDetailBloc.state.selectedUnit,
        mealDetailBloc.state.totalQuantityConverted,
        intakeTypeEntity,
        product,
        day);

    // Refresh Home Page
    locator<HomeBloc>().add(const LoadItemsEvent());

    // Refresh Diary Page
    locator<DiaryBloc>().add(const LoadDiaryYearEvent());
    locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());

    // Show snackbar and return to dashboard
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).infoAddedIntakeLabel)));
    Navigator.of(context)
        .popUntil(ModalRoute.withName(NavigationOptions.mainRoute));
  }

  DropdownMenuItem<String> _getServingDropdownItem(BuildContext context) {
    return DropdownMenuItem(
      value: UnitDropdownItem.serving.toString(),
      child: Text(
          product.servingSize ??
              '${S.of(context).servingLabel} (${product.servingQuantity} ${product.servingUnit})',
          overflow: TextOverflow.ellipsis,
          maxLines: 1),
    );
  }

  List<DropdownMenuItem<String>> _getSolidUnitDropdownItems(
      BuildContext context) {
    return [
      DropdownMenuItem(
          value: UnitDropdownItem.g.toString(),
          child: Text(S.of(context).gramUnit,
              overflow: TextOverflow.ellipsis, maxLines: 1)),
      DropdownMenuItem(
          value: UnitDropdownItem.oz.toString(),
          child: Text(S.of(context).ozUnit,
              overflow: TextOverflow.ellipsis, maxLines: 1)),
    ];
  }

  List<DropdownMenuItem<String>> _getLiquidUnitDropdownItems(
      BuildContext context) {
    return [
      DropdownMenuItem(
          value: UnitDropdownItem.ml.toString(),
          child: Text(S.of(context).milliliterUnit,
              overflow: TextOverflow.ellipsis, maxLines: 1)),
      DropdownMenuItem(
          value: UnitDropdownItem.flOz.toString(),
          child: Text(S.of(context).flOzUnit,
              overflow: TextOverflow.ellipsis, maxLines: 1)),
    ];
  }

  List<DropdownMenuItem<String>> _getOtherDropdownItems(BuildContext context) {
    return [
      DropdownMenuItem(
          value: UnitDropdownItem.gml.toString(),
          child: Text(
              "${S.of(context).notAvailableLabel} (${S.of(context).gramMilliliterUnit})",
              overflow: TextOverflow.ellipsis,
              maxLines: 1)),
    ];
  }
}
