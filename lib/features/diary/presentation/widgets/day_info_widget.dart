import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/activity_vertial_list.dart';
import 'package:opennutritracker/core/presentation/widgets/copy_or_delete_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/macro_nutriments_widget.dart';
import 'package:opennutritracker/core/presentation/widgets/copy_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/delete_dialog.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/custom_icons.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/daily_nutrient_panel.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_sort_type.dart';
import 'package:opennutritracker/features/home/presentation/widgets/intake_vertical_list.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

class DayInfoWidget extends StatefulWidget {
  final DateTime selectedDay;
  final TrackedDayEntity? trackedDayEntity;
  final List<UserActivityEntity> userActivities;
  final List<IntakeEntity> breakfastIntake;
  final List<IntakeEntity> lunchIntake;
  final List<IntakeEntity> dinnerIntake;
  final List<IntakeEntity> snackIntake;

  final bool usesImperialUnits;
  final bool showMealMacros;
  // Persisted per-meal sort preference loaded by [CalendarDayBloc]. Keys are
  // meal-type strings (breakfast / lunch / dinner / snack) and values are
  // [DiarySortType] enum indices. Null when the user has never picked a
  // sort, in which case every section starts on [DiarySortType.timeAdded].
  final Map<String, int>? diarySortPreferences;
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
    this.diarySortPreferences,
    required this.onDeleteIntake,
    required this.onDeleteActivity,
    required this.onCopyIntake,
    required this.onCopyActivity,
    this.onEditIntake,
    this.onEditActivity,
  });

  @override
  State<DayInfoWidget> createState() => _DayInfoWidgetState();
}

class _DayInfoWidgetState extends State<DayInfoWidget> {
  // Per-meal sort selection. Seeded from the persisted preferences on
  // [ConfigDBO] (via [CalendarDayBloc]) so the choice survives navigation
  // and app restart, and falls back to [DiarySortType.timeAdded] for any
  // meal type the user has not yet customised. We keep a local widget-state
  // copy so the picker updates optimistically without waiting for the next
  // calendar-day reload.
  late Map<IntakeTypeEntity, DiarySortType> _sortByMeal;

  @override
  void initState() {
    super.initState();
    _sortByMeal = _seedFromPreferences(widget.diarySortPreferences);
  }

  @override
  void didUpdateWidget(covariant DayInfoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the bloc emits an updated preference map (for example because the
    // user switched days and the freshly loaded config has a different
    // breakfast sort), reseed so the picker reflects what's persisted.
    if (oldWidget.diarySortPreferences != widget.diarySortPreferences) {
      _sortByMeal = _seedFromPreferences(widget.diarySortPreferences);
    }
  }

  Map<IntakeTypeEntity, DiarySortType> _seedFromPreferences(
    Map<String, int>? persisted,
  ) {
    Map<IntakeTypeEntity, DiarySortType> defaults() => {
          IntakeTypeEntity.breakfast: DiarySortType.timeAdded,
          IntakeTypeEntity.lunch: DiarySortType.timeAdded,
          IntakeTypeEntity.dinner: DiarySortType.timeAdded,
          IntakeTypeEntity.snack: DiarySortType.timeAdded,
        };

    if (persisted == null) return defaults();

    final seeded = defaults();
    for (final mealType in IntakeTypeEntity.values) {
      final storedIndex = persisted[mealType.name];
      if (storedIndex == null) continue;
      // Defensive bound check — if a future build ever removes a sort
      // option, an older index might land here. Falling back to the default
      // keeps the diary from crashing on stale data.
      if (storedIndex < 0 || storedIndex >= DiarySortType.values.length) {
        continue;
      }
      seeded[mealType] = DiarySortType.values[storedIndex];
    }
    return seeded;
  }

  void _setSortFor(IntakeTypeEntity mealType, DiarySortType sortType) {
    setState(() {
      _sortByMeal[mealType] = sortType;
    });
    // Persist asynchronously — we don't block the UI on the write. The
    // optimistic widget-state update above means the picker reflects the
    // user's choice immediately even if the disk write is still in flight.
    locator<CalendarDayBloc>()
        .setDiarySortPreference(mealType.name, sortType.index);
  }

  @override
  Widget build(BuildContext context) {
    final trackedDay = widget.trackedDayEntity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            DateFormat.yMMMMEEEEd().format(widget.selectedDay),
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
                          color: widget.trackedDayEntity
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
                                    color: widget.trackedDayEntity
                                        ?.getRatingDayTextColor(context),
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        MacroNutrientsView(
                          totalCarbsIntake: _allIntakes
                              .fold(0.0, (sum, i) => sum + i.totalCarbsGram),
                          totalFatsIntake: _allIntakes
                              .fold(0.0, (sum, i) => sum + i.totalFatsGram),
                          totalProteinsIntake: _allIntakes
                              .fold(0.0, (sum, i) => sum + i.totalProteinsGram),
                          totalCarbsGoal: trackedDay.carbsGoal ?? 0.0,
                          totalFatsGoal: trackedDay.fatGoal ?? 0.0,
                          totalProteinsGoal: trackedDay.proteinGoal ?? 0.0,
                        ),
                      ],
                    ),
                  )
                : const SizedBox(),
            // #160 + #173 + #404: Daily micronutrient panel — aggregates
            // ten nutrients (fibre, sodium, saturated fat, sugar, calcium,
            // iron, potassium, vitamin D, vitamin B12, magnesium) across
            // the day's intake list, with a Day/Week toggle that pulls the
            // previous six days' intakes itself via the locator. The
            // tracked-day entity is forwarded so the panel can prefer the
            // user's per-nutrient targets from Settings → Nutrient goals
            // when they've configured any (#173). No-op when there's
            // nothing logged for the current day yet.
            if (_allIntakes.isNotEmpty)
              DailyNutrientPanel(
                intakes: _allIntakes,
                selectedDay: widget.selectedDay,
                trackedDay: widget.trackedDayEntity,
              ),
            const SizedBox(height: 8.0),
            ActivityVerticalList(
              day: widget.selectedDay,
              title: S.of(context).activityLabel,
              userActivityList: widget.userActivities,
              onItemLongPressedCallback: onActivityItemLongPressed,
              onItemTappedCallback: widget.onEditActivity,
              onCopyActivityCallback:
                  DateUtils.isSameDay(widget.selectedDay, DateTime.now())
                      ? null
                      : (activity) =>
                          widget.onCopyActivity(activity, widget.trackedDayEntity),
            ),
            IntakeVerticalList(
              day: widget.selectedDay,
              title: S.of(context).breakfastLabel,
              listIcon: Icons.bakery_dining_outlined,
              addMealType: AddMealType.breakfastType,
              intakeList: _sortByMeal[IntakeTypeEntity.breakfast]!
                  .apply(widget.breakfastIntake),
              onDeleteIntakeCallback: widget.onDeleteIntake,
              onItemLongPressedCallback: onIntakeItemLongPressed,
              onItemTappedCallback: widget.onEditIntake,
              onCopyIntakeCallback:
                  DateUtils.isSameDay(widget.selectedDay, DateTime.now())
                      ? null
                      : widget.onCopyIntake,
              usesImperialUnits: widget.usesImperialUnits,
              showMealMacros: widget.showMealMacros,
              trackedDayEntity: trackedDay,
              sortType: _sortByMeal[IntakeTypeEntity.breakfast],
              onSortTypeChanged: (sort) =>
                  _setSortFor(IntakeTypeEntity.breakfast, sort),
            ),
            IntakeVerticalList(
              day: widget.selectedDay,
              title: S.of(context).lunchLabel,
              listIcon: Icons.lunch_dining_outlined,
              addMealType: AddMealType.lunchType,
              intakeList: _sortByMeal[IntakeTypeEntity.lunch]!
                  .apply(widget.lunchIntake),
              onDeleteIntakeCallback: widget.onDeleteIntake,
              onItemLongPressedCallback: onIntakeItemLongPressed,
              onItemTappedCallback: widget.onEditIntake,
              usesImperialUnits: widget.usesImperialUnits,
              showMealMacros: widget.showMealMacros,
              onCopyIntakeCallback:
                  DateUtils.isSameDay(widget.selectedDay, DateTime.now())
                      ? null
                      : widget.onCopyIntake,
              trackedDayEntity: trackedDay,
              sortType: _sortByMeal[IntakeTypeEntity.lunch],
              onSortTypeChanged: (sort) =>
                  _setSortFor(IntakeTypeEntity.lunch, sort),
            ),
            IntakeVerticalList(
              day: widget.selectedDay,
              title: S.of(context).dinnerLabel,
              listIcon: Icons.dinner_dining_outlined,
              addMealType: AddMealType.dinnerType,
              intakeList: _sortByMeal[IntakeTypeEntity.dinner]!
                  .apply(widget.dinnerIntake),
              onDeleteIntakeCallback: widget.onDeleteIntake,
              onItemLongPressedCallback: onIntakeItemLongPressed,
              onItemTappedCallback: widget.onEditIntake,
              onCopyIntakeCallback:
                  DateUtils.isSameDay(widget.selectedDay, DateTime.now())
                      ? null
                      : widget.onCopyIntake,
              usesImperialUnits: widget.usesImperialUnits,
              showMealMacros: widget.showMealMacros,
              sortType: _sortByMeal[IntakeTypeEntity.dinner],
              onSortTypeChanged: (sort) =>
                  _setSortFor(IntakeTypeEntity.dinner, sort),
            ),
            IntakeVerticalList(
              day: widget.selectedDay,
              title: S.of(context).snackLabel,
              listIcon: CustomIcons.food_apple_outline,
              addMealType: AddMealType.snackType,
              intakeList: _sortByMeal[IntakeTypeEntity.snack]!
                  .apply(widget.snackIntake),
              onDeleteIntakeCallback: widget.onDeleteIntake,
              onItemLongPressedCallback: onIntakeItemLongPressed,
              onItemTappedCallback: widget.onEditIntake,
              usesImperialUnits: widget.usesImperialUnits,
              showMealMacros: widget.showMealMacros,
              onCopyIntakeCallback:
                  DateUtils.isSameDay(widget.selectedDay, DateTime.now())
                      ? null
                      : widget.onCopyIntake,
              trackedDayEntity: trackedDay,
              sortType: _sortByMeal[IntakeTypeEntity.snack],
              onSortTypeChanged: (sort) =>
                  _setSortFor(IntakeTypeEntity.snack, sort),
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ],
    );
  }

  // #182: Compute from actual intakes instead of stale cached values
  List<IntakeEntity> get _allIntakes => [
        ...widget.breakfastIntake,
        ...widget.lunchIntake,
        ...widget.dinnerIntake,
        ...widget.snackIntake,
      ];

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
      widget.onCopyIntake(intakeEntity, null, selectedMealType);
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
      widget.onDeleteIntake(intakeEntity, widget.trackedDayEntity);
    }
  }

  void onIntakeItemLongPressed(
    BuildContext context,
    IntakeEntity intakeEntity,
  ) async {
    if (DateUtils.isSameDay(widget.selectedDay, DateTime.now())) {
      showDeleteIntakeDialog(context, intakeEntity);
    } else {
      showCopyOrDeleteIntakeDialog(context, intakeEntity);
    }
  }

  void onActivityItemLongPressed(
    BuildContext context,
    UserActivityEntity activityEntity,
  ) async {
    if (DateUtils.isSameDay(widget.selectedDay, DateTime.now())) {
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => const DeleteDialog(),
      );
      if (shouldDelete != null) {
        widget.onDeleteActivity(activityEntity, widget.trackedDayEntity);
      }
    } else {
      final copyOrDelete = await showDialog<bool>(
        context: context,
        builder: (context) => const CopyOrDeleteDialog(),
      );
      if (context.mounted) {
        if (copyOrDelete == false) {
          widget.onDeleteActivity(activityEntity, widget.trackedDayEntity);
        } else if (copyOrDelete == true) {
          widget.onCopyActivity(activityEntity, widget.trackedDayEntity);
        }
      }
    }
  }
}
