import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/serving_label_localizer.dart';
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
  final _quantityFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.quantityTextController.addListener(_onQuantityChanged);
    _quantityFocusNode.addListener(_onQuantityFocusChanged);
  }

  @override
  void dispose() {
    _quantityFocusNode.removeListener(_onQuantityFocusChanged);
    _quantityFocusNode.dispose();
    widget.quantityTextController.removeListener(_onQuantityChanged);
    super.dispose();
  }

  void _onQuantityFocusChanged() {
    if (_quantityFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_quantityFocusNode.hasFocus) return;
        _selectAllQuantityText();
      });
    }
  }

  void _selectAllQuantityText() {
    final text = widget.quantityTextController.text;
    widget.quantityTextController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: text.length,
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    return BottomSheet(
      elevation: 0,
      onClosing: () {},
      enableDrag: false,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: palette.border, width: Dimens.hairline),
            ),
            color: palette.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(Dimens.radiusL),
              topRight: Radius.circular(Dimens.radiusL),
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
                              focusNode: _quantityFocusNode,
                              onTap: _selectAllQuantityText,
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+([.,]\d{0,2})?$'),
                                ),
                              ],
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(
                                  borderRadius: Dimens.borderRadiusM,
                                ),
                                labelText: S.of(context).quantityLabel,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: DropdownButtonFormField(
                              isExpanded: true,
                              itemHeight: null,
                              initialValue: widget.selectedUnit,
                              key: ValueKey(widget.selectedUnit),
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(
                                  borderRadius: Dimens.borderRadiusM,
                                ),
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
                      if (!productMissingRequiredInfo) ...[
                        const SizedBox(height: Dimens.spacing12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: Dimens.spacing8,
                            children: [
                              // Quick-quantity presets — one tap to a common
                              // serving size instead of typing.
                              for (final preset in const [50, 100, 150, 200, 250])
                                ActionChip(
                                  label: Text('$preset'),
                                  onPressed: () {
                                    widget.quantityTextController.text = '$preset';
                                    widget.onQuantityOrUnitChanged(
                                      '$preset',
                                      widget.selectedUnit,
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: Dimens.spacing16),
                      Semantics(
                        identifier: 'meal-detail-add',
                        child: SizedBox(
                          width: double.infinity, // Make button full width
                          child: FilledButton.icon(
                            onPressed: !productMissingRequiredInfo
                                ? () {
                                    onAddButtonPressed(context);
                                  }
                                : null,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: Dimens.spacing16,
                              ),
                              shape: const RoundedRectangleBorder(
                                borderRadius: Dimens.borderRadiusM,
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded),
                            label: Text(S.of(context).addLabel),
                          ),
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
    // Custom meals are seeded from MealEntity.empty(), which carries an empty
    // servingSize string rather than null. An empty (or whitespace-only)
    // description should fall through to the constructed label so the option
    // doesn't render blank — otherwise '' wins over the ?? fallback (#495).
    final servingSize = widget.product.servingSize;
    // Serving labels are stored in English (see MealEntity._spServingLabel);
    // translate the common household units at display time.
    final servingText = (servingSize != null && servingSize.trim().isNotEmpty)
        ? localizeServingLabel(S.of(context), servingSize)
        : '${S.of(context).servingLabel} (${widget.product.servingQuantity} ${widget.product.servingUnit})';
    return DropdownMenuItem(
      value: UnitDropdownItem.serving.toString(),
      child: Text(
        servingText,
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
