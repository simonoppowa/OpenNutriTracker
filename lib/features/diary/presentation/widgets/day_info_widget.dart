import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/activity_vertial_list.dart';
import 'package:opennutritracker/core/presentation/widgets/copy_or_delete_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/copy_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/delete_dialog.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/custom_icons.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/home/presentation/widgets/intake_vertical_list.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

class DayInfoWidget extends StatelessWidget {
  final DateTime selectedDay;
  final TrackedDayEntity? trackedDayEntity;
  final List<UserActivityEntity> userActivities;
  final List<IntakeEntity> breakfastIntake;
  final List<IntakeEntity> lunchIntake;
  final List<IntakeEntity> dinnerIntake;
  final List<IntakeEntity> snackIntake;
  // #150: per-meal recommended kcal targets for the selected calendar day.
  // 0 means no target should be shown for that section (e.g. days with no
  // tracked daily goal).
  final double breakfastKcalTarget;
  final double lunchKcalTarget;
  final double dinnerKcalTarget;
  final double snackKcalTarget;

  final bool usesImperialUnits;
  final bool showMealMacros;
  final Function(IntakeEntity intake, TrackedDayEntity? trackedDayEntity)
      onDeleteIntake;
  final Function(
    UserActivityEntity userActivityEntity,
    TrackedDayEntity? trackedDayEntity,
  ) onDeleteActivity;
  final Function(
    IntakeEntity intake,
    TrackedDayEntity? trackedDayEntity,
    AddMealType? type,
  ) onCopyIntake;
  final Function(
    UserActivityEntity userActivityEntity,
    TrackedDayEntity? trackedDayEntity,
  ) onCopyActivity;
  final Function(BuildContext context, IntakeEntity intake, bool usesImperialUnits)?
      onEditIntake;
  final Function(BuildContext context, UserActivityEntity activity)?
      onEditActivity;

  const DayInfoWidget({
    super.key,
    required this.selectedDay,
    required this.trackedDayEntity,
    required this.userActivities,
    required this.breakfastIntake,
    required this.lunchIntake,
    required this.dinnerIntake,
    required this.snackIntake,
    required this.usesImperialUnits,
    this.showMealMacros = true,
    required this.onDeleteIntake,
    required this.onDeleteActivity,
    required this.onCopyIntake,
    required this.onCopyActivity,
    this.onEditIntake,
    this.onEditActivity,
    this.breakfastKcalTarget = 0,
    this.lunchKcalTarget = 0,
    this.dinnerKcalTarget = 0,
    this.snackKcalTarget = 0,
  });

  @override
  Widget build(BuildContext context) {
    final trackedDay = trackedDayEntity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            DateFormat.yMMMMEEEEd().format(selectedDay),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 8.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            trackedDay == null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      S.of(context).nothingAddedLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                    ),
                  )
                : const SizedBox(),
            trackedDay != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 0.0,
                          margin: const EdgeInsets.all(0.0),
                          color: trackedDayEntity
                              ?.getRatingDayTextBackgroundColor(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 8.0,
                            ),
                            child: Text(
                              _getCaloriesTrackedDisplayString(
                                  context, trackedDay),
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                    color:
                                        trackedDayEntity?.getRatingDayTextColor(
                                      context,
                                    ),
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          _getMacroTrackedDisplayString(trackedDay),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(),
            const SizedBox(height: 8.0),
            ActivityVerticalList(
              day: selectedDay,
              title: S.of(context).activityLabel,
              userActivityList: userActivities,
              onItemLongPressedCallback: onActivityItemLongPressed,
              onItemTappedCallback: onEditActivity,
              onCopyActivityCallback:
                  DateUtils.isSameDay(selectedDay, DateTime.now())
                      ? null
                      : (activity) =>
                          onCopyActivity(activity, trackedDayEntity),
            ),
            IntakeVerticalList(
              day: selectedDay,
              title: S.of(context).breakfastLabel,
              listIcon: Icons.bakery_dining_outlined,
              addMealType: AddMealType.breakfastType,
              intakeList: breakfastIntake,
              onDeleteIntakeCallback: onDeleteIntake,
              onItemLongPressedCallback: onIntakeItemLongPressed,
              onItemTappedCallback: onEditIntake,
              onCopyIntakeCallback:
                  DateUtils.isSameDay(selectedDay, DateTime.now())
                      ? null
                      : onCopyIntake,
              usesImperialUnits: usesImperialUnits,
              showMealMacros: showMealMacros,
              trackedDayEntity: trackedDay,
              mealKcalTarget: breakfastKcalTarget,
            ),
            IntakeVerticalList(
              day: selectedDay,
              title: S.of(context).lunchLabel,
              listIcon: Icons.lunch_dining_outlined,
              addMealType: AddMealType.lunchType,
              intakeList: lunchIntake,
              onDeleteIntakeCallback: onDeleteIntake,
              onItemLongPressedCallback: onIntakeItemLongPressed,
              onItemTappedCallback: onEditIntake,
              usesImperialUnits: usesImperialUnits,
              showMealMacros: showMealMacros,
              onCopyIntakeCallback:
                  DateUtils.isSameDay(selectedDay, DateTime.now())
                      ? null
                      : onCopyIntake,
              trackedDayEntity: trackedDay,
              mealKcalTarget: lunchKcalTarget,
            ),
            IntakeVerticalList(
              day: selectedDay,
              title: S.of(context).dinnerLabel,
              listIcon: Icons.dinner_dining_outlined,
              addMealType: AddMealType.dinnerType,
              intakeList: dinnerIntake,
              onDeleteIntakeCallback: onDeleteIntake,
              onItemLongPressedCallback: onIntakeItemLongPressed,
              onItemTappedCallback: onEditIntake,
              onCopyIntakeCallback:
                  DateUtils.isSameDay(selectedDay, DateTime.now())
                      ? null
                      : onCopyIntake,
              usesImperialUnits: usesImperialUnits,
              showMealMacros: showMealMacros,
              mealKcalTarget: dinnerKcalTarget,
            ),
            IntakeVerticalList(
              day: selectedDay,
              title: S.of(context).snackLabel,
              listIcon: CustomIcons.food_apple_outline,
              addMealType: AddMealType.snackType,
              intakeList: snackIntake,
              onDeleteIntakeCallback: onDeleteIntake,
              onItemLongPressedCallback: onIntakeItemLongPressed,
              onItemTappedCallback: onEditIntake,
              usesImperialUnits: usesImperialUnits,
              showMealMacros: showMealMacros,
              onCopyIntakeCallback:
                  DateUtils.isSameDay(selectedDay, DateTime.now())
                      ? null
                      : onCopyIntake,
              trackedDayEntity: trackedDay,
              mealKcalTarget: snackKcalTarget,
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ],
    );
  }

  // #182: Compute from actual intakes instead of stale cached values
  List<IntakeEntity> get _allIntakes =>
      [...breakfastIntake, ...lunchIntake, ...dinnerIntake, ...snackIntake];

  String _getCaloriesTrackedDisplayString(
      BuildContext context, TrackedDayEntity trackedDay) {
    final actualKcal = _allIntakes.fold(0.0, (sum, i) => sum + i.totalKcal);
    final usesKilojoules =
        context.watch<EnergyUnitProvider>().usesKilojoules;
    final clampedKcal = actualKcal < 0 ? 0.0 : actualKcal;
    final displayActual = usesKilojoules
        ? UnitCalc.kcalToKj(clampedKcal).toInt()
        : clampedKcal.toInt();
    final displayGoal = usesKilojoules
        ? UnitCalc.kcalToKj(trackedDay.calorieGoal).toInt()
        : trackedDay.calorieGoal.toInt();
    final unit = usesKilojoules ? S.of(context).kjLabel : S.of(context).kcalLabel;
    return '$displayActual/$displayGoal $unit';
  }

  String _getMacroTrackedDisplayString(TrackedDayEntity trackedDay) {
    final carbsTracked =
        _allIntakes.fold(0.0, (sum, i) => sum + i.totalCarbsGram).floor();
    final fatTracked =
        _allIntakes.fold(0.0, (sum, i) => sum + i.totalFatsGram).floor();
    final proteinTracked =
        _allIntakes.fold(0.0, (sum, i) => sum + i.totalProteinsGram).floor();

    final carbsGoal = trackedDay.carbsGoal?.floor().toString() ?? '?';
    final fatGoal = trackedDay.fatGoal?.floor().toString() ?? '?';
    final proteinGoal = trackedDay.proteinGoal?.floor().toString() ?? '?';

    return 'Carbs: $carbsTracked/${carbsGoal}g, Fat: $fatTracked/${fatGoal}g, Protein: $proteinTracked/${proteinGoal}g';
  }

  void showCopyOrDeleteIntakeDialog(
    BuildContext context,
    IntakeEntity intakeEntity,
  ) async {
    final copyOrDelete = await showDialog<bool>(
      context: context,
      builder: (context) => const CopyOrDeleteDialog(),
    );
    if (context.mounted) {
      if (copyOrDelete != null && !copyOrDelete) {
        showDeleteIntakeDialog(context, intakeEntity);
      } else if (copyOrDelete != null && copyOrDelete) {
        showCopyDialog(context, intakeEntity);
      }
    }
  }

  void showCopyDialog(BuildContext context, IntakeEntity intakeEntity) async {
    final defaultMealType = switch (intakeEntity.type) {
      IntakeTypeEntity.breakfast => AddMealType.breakfastType,
      IntakeTypeEntity.lunch => AddMealType.lunchType,
      IntakeTypeEntity.dinner => AddMealType.dinnerType,
      IntakeTypeEntity.snack => AddMealType.snackType,
    };

    final copyDialog = CopyDialog(
      initialValue: defaultMealType,
    );
    final selectedMealType = await showDialog<AddMealType>(
      context: context,
      builder: (context) => copyDialog,
    );
    if (selectedMealType != null) {
      onCopyIntake(intakeEntity, null, selectedMealType);
    }
  }

  void showDeleteIntakeDialog(
    BuildContext context,
    IntakeEntity intakeEntity,
  ) async {
    final shouldDeleteIntake = await showDialog<bool>(
      context: context,
      builder: (context) => const DeleteDialog(),
    );
    if (shouldDeleteIntake != null) {
      onDeleteIntake(intakeEntity, trackedDayEntity);
    }
  }

  void onIntakeItemLongPressed(
    BuildContext context,
    IntakeEntity intakeEntity,
  ) async {
    if (DateUtils.isSameDay(selectedDay, DateTime.now())) {
      showDeleteIntakeDialog(context, intakeEntity);
    } else {
      showCopyOrDeleteIntakeDialog(context, intakeEntity);
    }
  }

  void onActivityItemLongPressed(
    BuildContext context,
    UserActivityEntity activityEntity,
  ) async {
    if (DateUtils.isSameDay(selectedDay, DateTime.now())) {
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => const DeleteDialog(),
      );
      if (shouldDelete != null) {
        onDeleteActivity(activityEntity, trackedDayEntity);
      }
    } else {
      final copyOrDelete = await showDialog<bool>(
        context: context,
        builder: (context) => const CopyOrDeleteDialog(),
      );
      if (context.mounted) {
        if (copyOrDelete == false) {
          onDeleteActivity(activityEntity, trackedDayEntity);
        } else if (copyOrDelete == true) {
          onCopyActivity(activityEntity, trackedDayEntity);
        }
      }
    }
  }
}
