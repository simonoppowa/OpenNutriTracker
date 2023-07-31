import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/custom_text_input_formatter.dart';
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

  const MealDetailBottomSheet(
      {Key? key,
      required this.product,
      required this.day,
      required this.intakeTypeEntity,
      required this.mealDetailBloc,
      required this.quantityTextController})
      : super(key: key);

  @override
  State<MealDetailBottomSheet> createState() => _MealDetailBottomSheetState();
}

class _MealDetailBottomSheetState extends State<MealDetailBottomSheet> {
  late bool _productMissingRequiredInfo;

  @override
  void initState() {
    _productMissingRequiredInfo = _hasRequiredProductInfoMissing();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
                              enabled: !_productMissingRequiredInfo,
                              controller: widget.quantityTextController,
                              keyboardType: TextInputType.number,
                              inputFormatters:
                                  CustomTextInputFormatter.doubleOnly(),
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: S.of(context).quantityLabel,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                              child: DropdownButtonFormField(
                                  decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      labelText: S.of(context).unitLabel),
                                  items: <DropdownMenuItem<String>>[
                                    DropdownMenuItem(
                                        child: Text(widget.product.mealUnit ??
                                            S.of(context).gramMilliliterUnit))
                                  ],
                                  onChanged: null // deactivate item,
                                  ))
                        ],
                      ),
                      SizedBox(
                        width: double.infinity, // Make button full width
                        child: ElevatedButton.icon(
                            onPressed: !_productMissingRequiredInfo
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
                      _productMissingRequiredInfo
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

  void onAddButtonPressed(BuildContext context) {
    widget.mealDetailBloc.addIntake(
        context,
        widget.product.mealUnit ?? S.of(context).gramMilliliterUnit,
        widget.quantityTextController.text,
        widget.intakeTypeEntity,
        widget.product,
        widget.day);

    // Refresh Home Page
    locator<HomeBloc>().add(const LoadItemsEvent());

    // Refresh Diary Page
    locator<DiaryBloc>().add(const LoadDiaryYearEvent());
    locator<CalendarDayBloc>().add(LoadCalendarDayEvent(DateTime.now()));

    // Show snackbar and return to dashboard
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).infoAddedIntakeLabel)));
    Navigator.of(context)
        .popUntil(ModalRoute.withName(NavigationOptions.mainRoute));
  }
}
