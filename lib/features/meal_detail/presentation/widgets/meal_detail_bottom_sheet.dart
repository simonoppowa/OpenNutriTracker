import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MealDetailBottomSheet extends StatefulWidget {
  final MealEntity product;
  final DateTime day;
  final IntakeTypeEntity intakeTypeEntity;
  final TextEditingController quantityTextController;
  final MealDetailBloc mealDetailBloc;

  final String selectedUnit;

  final Function(String?, String?) onQuantityOrUnitChanged;

  const MealDetailBottomSheet({
    super.key,
    required this.product,
    required this.day,
    required this.intakeTypeEntity,
    required this.quantityTextController,
    required this.onQuantityOrUnitChanged,
    required this.mealDetailBloc,
    required this.selectedUnit,
  });

  @override
  State<MealDetailBottomSheet> createState() => _MealDetailBottomSheetState();
}

class _MealDetailBottomSheetState extends State<MealDetailBottomSheet> {
  @override
  void initState() {
    super.initState();
    widget.quantityTextController.addListener(_onQuantityChanged);
  }

  @override
  void dispose() {
    widget.quantityTextController.removeListener(_onQuantityChanged);
    super.dispose();
  }

  void _onQuantityChanged() {
    widget.onQuantityOrUnitChanged(
      widget.quantityTextController.text,
      widget.selectedUnit,
    );
  }

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
          child: SafeArea(
            top: false,
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
                              controller: widget.quantityTextController,
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+([.,]\d{0,2})?$'),
                                ),
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
                              initialValue: widget.selectedUnit,
                              key: ValueKey(widget.selectedUnit),
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: S.of(context).unitLabel,
                              ),
                              items: <DropdownMenuItem<String>>[
                                if (widget.product.hasServingValues)
                                  _getServingDropdownItem(context),
                                if (widget.product.isSolid ||
                                    !widget.product.isLiquid &&
                                        !widget.product.isSolid)
                                  ..._getSolidUnitDropdownItems(context),
                                if (widget.product.isLiquid ||
                                    !widget.product.isLiquid &&
                                        !widget.product.isSolid)
                                  ..._getLiquidUnitDropdownItems(context),
                                ..._getOtherDropdownItems(context),
                              ],
                              onChanged: (value) {
                                widget.onQuantityOrUnitChanged(
                                  widget.quantityTextController.text,
                                  value,
                                );
                              },
                            ),
                          ),
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
                          style:
                              ElevatedButton.styleFrom(
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                              ).copyWith(
                                elevation: ButtonStyleButton.allOrNull(0.0),
                              ),
                          icon: const Icon(Icons.add_outlined),
                          label: Text(S.of(context).addLabel),
                        ),
                      ),
                      productMissingRequiredInfo
                          ? Text(
                              S.of(context).missingProductInfo,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            )
                          : const SizedBox(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _hasRequiredProductInfoMissing() {
    final productNutriments = widget.product.nutriments;
    if (productNutriments.energyKcal100 == null ||
        productNutriments.carbohydrates100 == null ||
        productNutriments.fat100 == null ||
        productNutriments.proteins100 == null) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> onAddButtonPressed(BuildContext context) async {
    // Validate quantity (#209, #210)
    final quantityText = widget.quantityTextController.text.replaceAll(
      ',',
      '.',
    );
    final quantity = double.tryParse(quantityText);

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${S.of(context).quantityLabel} must be greater than 0',
          ),
        ),
      );
      return;
    }

    // Reasonable maximum limit per meal (#210)
    if (quantity > 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${S.of(context).quantityLabel} seems unrealistically high',
          ),
        ),
      );
      return;
    }

    // Check for duplicate additions (#212)
    final isDuplicate = await _checkForDuplicate(context);
    if (!context.mounted) return;
    if (isDuplicate) {
      final shouldAdd = await _showDuplicateDialog(context);
      if (!context.mounted) return;
      if (shouldAdd != true) return;
    }

    widget.mealDetailBloc.addIntake(
      context,
      widget.mealDetailBloc.state.selectedUnit,
      widget.mealDetailBloc.state.totalQuantityConverted,
      widget.intakeTypeEntity,
      widget.product,
      widget.day,
    );

    // Refresh Home Page
    locator<HomeBloc>().add(const LoadItemsEvent());

    // Refresh Diary Page - Pass the day to preserve selection (#154)
    locator<DiaryBloc>().add(const LoadDiaryYearEvent());
    locator<CalendarDayBloc>().add(const RefreshCalendarDayEvent());

    // Show snackbar and return to dashboard
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(S.of(context).infoAddedIntakeLabel)));
    Navigator.of(
      context,
    ).popUntil(ModalRoute.withName(NavigationOptions.mainRoute));
  }

  // #212: Check if this meal was already added today for the same meal type
  Future<bool> _checkForDuplicate(BuildContext context) async {
    final getIntakeUsecase = locator<GetIntakeUsecase>();
    final List<IntakeEntity> todayIntakes;

    switch (widget.intakeTypeEntity) {
      case IntakeTypeEntity.breakfast:
        todayIntakes = await getIntakeUsecase.getBreakfastIntakeByDay(
          widget.day,
        );
        break;
      case IntakeTypeEntity.lunch:
        todayIntakes = await getIntakeUsecase.getLunchIntakeByDay(widget.day);
        break;
      case IntakeTypeEntity.dinner:
        todayIntakes = await getIntakeUsecase.getDinnerIntakeByDay(widget.day);
        break;
      case IntakeTypeEntity.snack:
        todayIntakes = await getIntakeUsecase.getSnackIntakeByDay(widget.day);
        break;
    }

    // Check if meal with same code or name already exists
    return todayIntakes.any(
      (intake) =>
          (widget.product.code != null &&
              intake.meal.code == widget.product.code) ||
          (widget.product.name != null &&
              intake.meal.name == widget.product.name),
    );
  }

  // #212: Show confirmation dialog for duplicate meals
  Future<bool?> _showDuplicateDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).warningLabel),
          content: Text(S.of(context).duplicateMealDialogContent),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(S.of(context).dialogCancelLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(S.of(context).addLabel),
            ),
          ],
        );
      },
    );
  }

  DropdownMenuItem<String> _getServingDropdownItem(BuildContext context) {
    return DropdownMenuItem(
      value: UnitDropdownItem.serving.toString(),
      child: Text(
        widget.product.servingSize ??
            '${S.of(context).servingLabel} (${widget.product.servingQuantity} ${widget.product.servingUnit})',
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  List<DropdownMenuItem<String>> _getSolidUnitDropdownItems(
    BuildContext context,
  ) {
    return [
      DropdownMenuItem(
        value: UnitDropdownItem.g.toString(),
        child: Text(
          S.of(context).gramUnit,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      DropdownMenuItem(
        value: UnitDropdownItem.oz.toString(),
        child: Text(
          S.of(context).ozUnit,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    ];
  }

  List<DropdownMenuItem<String>> _getLiquidUnitDropdownItems(
    BuildContext context,
  ) {
    return [
      DropdownMenuItem(
        value: UnitDropdownItem.ml.toString(),
        child: Text(
          S.of(context).milliliterUnit,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      DropdownMenuItem(
        value: UnitDropdownItem.flOz.toString(),
        child: Text(
          S.of(context).flOzUnit,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    ];
  }

  List<DropdownMenuItem<String>> _getOtherDropdownItems(BuildContext context) {
    return [
      DropdownMenuItem(
        value: UnitDropdownItem.gml.toString(),
        child: Text(
          "${S.of(context).notAvailableLabel} (${S.of(context).gramMilliliterUnit})",
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    ];
  }
}
