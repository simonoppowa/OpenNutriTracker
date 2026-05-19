import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/copy_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/delete_all_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_card.dart';
import 'package:opennutritracker/core/presentation/widgets/placeholder_card.dart';
import 'package:opennutritracker/core/presentation/widgets/share_qr_dialog.dart';
import 'package:opennutritracker/core/utils/energy_display.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/core/utils/vertical_list_popup_menu_selections.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_screen.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_sort_type.dart';
import 'package:opennutritracker/features/home/domain/entity/shared_meal_payload.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/home/presentation/screens/import_meal_scanner_screen.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class IntakeVerticalList extends StatefulWidget {
  final DateTime day;
  final String title;
  final IconData listIcon;
  final AddMealType addMealType;
  final List<IntakeEntity> intakeList;
  final bool usesImperialUnits;
  final bool showMealMacros;
  final Function(IntakeEntity intake, TrackedDayEntity? trackedDayEntity)
      onDeleteIntakeCallback;
  final Function(BuildContext, IntakeEntity)? onItemLongPressedCallback;
  final Function(bool)? onItemDragCallback;
  final Function(BuildContext, IntakeEntity, bool)? onItemTappedCallback;
  final Function(IntakeEntity intake, TrackedDayEntity? trackedDayEntity,
      AddMealType? type)? onCopyIntakeCallback;
  final TrackedDayEntity? trackedDayEntity;
  // #150: optional recommended kcal target for this meal section. When
  // supplied and > 0, the section header shows "consumed / target kcal" so
  // someone scanning the day can see at a glance whether breakfast (or any
  // other meal) sat inside the share they had planned for it.
  final double? mealKcalTarget;

  /// Current sort applied to [intakeList]. When non-null (and
  /// [onSortTypeChanged] is also provided), a small sort menu is rendered in
  /// the section header. Callers are responsible for sorting [intakeList]
  /// before it reaches the widget — this field only drives the menu's
  /// highlighted selection.
  final DiarySortType? sortType;

  /// Called when the user picks a new sort option from the section header.
  /// When null, the sort menu is hidden.
  final ValueChanged<DiarySortType>? onSortTypeChanged;

  const IntakeVerticalList({
    super.key,
    required this.day,
    required this.title,
    required this.listIcon,
    required this.addMealType,
    required this.intakeList,
    required this.usesImperialUnits,
    this.showMealMacros = true,
    required this.onDeleteIntakeCallback,
    this.onItemLongPressedCallback,
    this.onItemDragCallback,
    this.onItemTappedCallback,
    this.onCopyIntakeCallback,
    this.trackedDayEntity,
    this.mealKcalTarget,
    this.sortType,
    this.onSortTypeChanged,
  });

  @override
  State<IntakeVerticalList> createState() => _IntakeVerticalListState();
}

class _IntakeVerticalListState extends State<IntakeVerticalList> {
  late MealDetailBloc _mealDetailBloc;
  late HomeBloc _homeBloc;

  @override
  void initState() {
    _mealDetailBloc = locator<MealDetailBloc>();
    _homeBloc = locator<HomeBloc>();
    super.initState();
  }

  double get totalKcal {
    return widget.intakeList
        .fold(0, (previousValue, element) => previousValue + element.totalKcal);
  }

  double get totalCarbsGram {
    return widget.intakeList
        .fold(0, (previousValue, element) => previousValue + element.totalCarbsGram);
  }

  double get totalFatsGram {
    return widget.intakeList
        .fold(0, (previousValue, element) => previousValue + element.totalFatsGram);
  }

  double get totalProteinsGram {
    return widget.intakeList
        .fold(0, (previousValue, element) => previousValue + element.totalProteinsGram);
  }

  // #150: only show a header when we have something to say — either some
  // food was logged, or a recommended target exists so the section can read
  // "0 / 600 kcal" before anything is logged.
  bool get _hasMealKcalTarget =>
      widget.mealKcalTarget != null && widget.mealKcalTarget! > 0;

  bool get _shouldShowHeaderSummary => totalKcal > 0 || _hasMealKcalTarget;

  String _buildHeaderSummary(BuildContext context) {
    final consumed = EnergyDisplay.formatValue(context, totalKcal);
    final kcalLine = _hasMealKcalTarget
        ? S.of(context).diaryMealKcalConsumedOfTarget(
              consumed,
              EnergyDisplay.formatValue(context, widget.mealKcalTarget!),
            )
        : EnergyDisplay.formatWithUnit(context, totalKcal);
    if (widget.showMealMacros && totalKcal > 0) {
      return '$kcalLine\n'
          '${totalCarbsGram.toInt()} ${S.of(context).carbsLabelShort}  '
          '${totalFatsGram.toInt()} ${S.of(context).fatLabelShort}  '
          '${totalProteinsGram.toInt()} ${S.of(context).proteinLabelShort}';
    }
    return kcalLine;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Icon(widget.listIcon,
                  size: 24, color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 4.0),
              Text(
                widget.title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
              const Spacer(),
              if (_shouldShowHeaderSummary)
                Text(
                  _buildHeaderSummary(context),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7)),
                  textAlign: TextAlign.center,
                ),
              if (widget.onSortTypeChanged != null && totalKcal > 0)
                _buildSortMenu(context),
              PopupMenuButton<VerticalListPopupMenuSelections>(
                    onSelected:
                        (VerticalListPopupMenuSelections selection) async {
                      switch (selection) {
                        case VerticalListPopupMenuSelections.onCopy:
                          final copyDialog =
                              CopyDialog(initialValue: widget.addMealType);
                          final selectedMealType =
                              await showDialog<AddMealType>(
                                  context: context,
                                  builder: (context) => copyDialog);
                          if (selectedMealType != null) {
                            for (IntakeEntity intake in widget.intakeList) {
                              widget.onCopyIntakeCallback!(
                                  intake, null, selectedMealType);
                            }
                          }
                          break;
                        case VerticalListPopupMenuSelections.onDelete:
                          final shouldDeleteIntakes = await showDialog<bool>(
                              context: context,
                              builder: (context) => const DeleteAllDialog());
                          if (shouldDeleteIntakes != null) {
                            for (IntakeEntity intake in widget.intakeList) {
                              widget.onDeleteIntakeCallback(
                                  intake, widget.trackedDayEntity);
                            }
                            break;
                          }
                        case VerticalListPopupMenuSelections.onShare:
                          if (context.mounted) {
                            final code = SharedMealPayload.fromIntakeList(
                              widget.intakeList,
                              recipeRepository: locator<RecipeRepository>(),
                            ).toJsonString();
                            await showDialog(
                              context: context,
                              builder: (_) => ShareQrDialog(
                                title: S.of(context).shareMealLabel,
                                code: code,
                                fileBaseName: 'meal_qr',
                              ),
                            );
                          }
                        case VerticalListPopupMenuSelections.onImport:
                          if (context.mounted) {
                            Navigator.of(context).pushNamed(
                              NavigationOptions.importMealScannerRoute,
                              arguments: ImportMealScannerArguments(
                                widget.addMealType.getIntakeType(),
                                widget.addMealType,
                                widget.day,
                              ),
                            );
                          }
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<VerticalListPopupMenuSelections>>[
                          if (widget.onCopyIntakeCallback != null &&
                              totalKcal > 0)
                            PopupMenuItem<VerticalListPopupMenuSelections>(
                                value: VerticalListPopupMenuSelections.onCopy,
                                child: Text(S.of(context).dialogCopyLabel)),
                          if (totalKcal > 0)
                            PopupMenuItem<VerticalListPopupMenuSelections>(
                                value: VerticalListPopupMenuSelections.onDelete,
                                child: Text(S.of(context).deleteAllLabel)),
                          if (totalKcal > 0)
                            PopupMenuItem<VerticalListPopupMenuSelections>(
                                value: VerticalListPopupMenuSelections.onShare,
                                child: Text(S.of(context).shareMealLabel)),
                          PopupMenuItem<VerticalListPopupMenuSelections>(
                              value: VerticalListPopupMenuSelections.onImport,
                              child: Text(S.of(context).importMealLabel)),
                        ]),
            ],
          ),
        ),
        DragTarget<IntakeEntity>(
          onAcceptWithDetails: (intake) {
            _onItemDropped(intake.data);
          },
          builder: (context, candidateData, rejectedData) {
            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.intakeList.length + 1,
                // List length + placeholder card
                itemBuilder: (BuildContext context, int index) {
                  final firstListElement = index == 0 ? true : false;
                  if (index == widget.intakeList.length) {
                    return PlaceholderCard(
                        day: widget.day,
                        onTap: () => _onPlaceholderCardTapped(context),
                        firstListElement: firstListElement);
                  } else {
                    final intakeEntity = widget.intakeList[index];
                    return LongPressDraggable<IntakeEntity>(
                      onDragStarted: () {
                        widget.onItemDragCallback?.call(true);
                      },
                      onDragEnd: (details) {
                        widget.onItemDragCallback?.call(false);
                      },
                      data: intakeEntity,
                      feedback: Material(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Opacity(
                          opacity: 0.7,
                          child: IntakeCard(
                            key: ValueKey(intakeEntity.meal.code),
                            intake: intakeEntity,
                            firstListElement: false,
                            usesImperialUnits: widget.usesImperialUnits,
                          ),
                        ),
                      ),
                      childWhenDragging: Row(
                        children: [
                          SizedBox(width: firstListElement ? 16 : 0),
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              color: Theme.of(context).cardColor,
                            ),
                          ),
                        ],
                      ),
                      child: IntakeCard(
                        key: ValueKey(intakeEntity.meal.code),
                        intake: intakeEntity,
                        onItemLongPressed: widget.onItemLongPressedCallback,
                        onItemTapped: widget.onItemTappedCallback,
                        firstListElement: firstListElement,
                        usesImperialUnits: widget.usesImperialUnits,
                      ),
                    );
                  }
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSortMenu(BuildContext context) {
    final current = widget.sortType ?? DiarySortType.timeAdded;
    return Semantics(
      identifier: 'diary-section-sort-menu',
      child: PopupMenuButton<DiarySortType>(
        tooltip: S.of(context).diarySortByLabel,
        icon: const Icon(Icons.sort),
        initialValue: current,
        onSelected: (sort) => widget.onSortTypeChanged?.call(sort),
        itemBuilder: (context) => <PopupMenuEntry<DiarySortType>>[
          CheckedPopupMenuItem<DiarySortType>(
            value: DiarySortType.timeAdded,
            checked: current == DiarySortType.timeAdded,
            child: Text(S.of(context).diarySortByTime),
          ),
          CheckedPopupMenuItem<DiarySortType>(
            value: DiarySortType.kcal,
            checked: current == DiarySortType.kcal,
            child: Text(S.of(context).diarySortByKcal),
          ),
          CheckedPopupMenuItem<DiarySortType>(
            value: DiarySortType.protein,
            checked: current == DiarySortType.protein,
            child: Text(S.of(context).diarySortByProtein),
          ),
          CheckedPopupMenuItem<DiarySortType>(
            value: DiarySortType.carbs,
            checked: current == DiarySortType.carbs,
            child: Text(S.of(context).diarySortByCarbs),
          ),
          CheckedPopupMenuItem<DiarySortType>(
            value: DiarySortType.fat,
            checked: current == DiarySortType.fat,
            child: Text(S.of(context).diarySortByFat),
          ),
        ],
      ),
    );
  }

  void _onPlaceholderCardTapped(BuildContext context) {
    Navigator.pushNamed(context, NavigationOptions.addMealRoute,
        arguments: AddMealScreenArguments(widget.addMealType, widget.day));
  }

  void _onItemDropped(IntakeEntity entity) {
    _mealDetailBloc.addIntake(context, entity.unit, entity.amount.toString(),
        widget.addMealType.getIntakeType(), entity.meal, entity.dateTime);
    _homeBloc.deleteIntakeItem(entity);

    // Refresh Home Page
    locator<HomeBloc>().add(const LoadItemsEvent());

    // Refresh Diary Page
    locator<DiaryBloc>().add(const LoadDiaryYearEvent());
    locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());
  }
}
