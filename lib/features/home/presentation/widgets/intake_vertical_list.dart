import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_profiles_usecase.dart';
import 'package:opennutritracker/core/presentation/widgets/copy_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/copy_to_profile_sheet.dart';
import 'package:opennutritracker/core/presentation/widgets/delete_all_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_card.dart';
import 'package:opennutritracker/core/presentation/widgets/placeholder_card.dart';
import 'package:opennutritracker/core/presentation/widgets/share_qr_dialog.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final accent = Theme.of(context).colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(
            Dimens.spacing16,
            Dimens.spacing20,
            Dimens.spacing12,
            Dimens.spacing8,
          ),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Dimens.spacing8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: Dimens.borderRadiusS,
                ),
                child: Icon(widget.listIcon, size: 20, color: accent),
              ),
              const SizedBox(width: Dimens.spacing12),
              Flexible(
                child: Text(
                  widget.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(
                    color: palette.textStrong,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              if (_shouldShowHeaderSummary)
                Flexible(
                  child: Text(
                    _buildHeaderSummary(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(
                      color: palette.textMuted,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              if (widget.onSortTypeChanged != null && totalKcal > 0)
                _buildSortMenu(context),
              Semantics(
                  identifier: 'intake-section-menu',
                  // Tight bounds: without this the node inherits the flex
                  // Row's full-width box and coordinate taps miss the button.
                  container: true,
                  child: PopupMenuButton<VerticalListPopupMenuSelections>(
                    icon: Icon(Icons.more_vert_rounded, color: palette.textMuted),
                    shape: Dimens.shapeM,
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
                            final hasOtherProfiles =
                                locator<GetProfilesUsecase>()
                                        .getProfiles()
                                        .length >
                                    1;
                            await showDialog(
                              context: context,
                              builder: (_) => ShareQrDialog(
                                title: S.of(context).shareMealLabel,
                                code: code,
                                fileBaseName: 'meal_qr',
                                onCopyToProfile: hasOtherProfiles
                                    ? () => showCopyToProfileSheet(
                                          context,
                                          widget.intakeList,
                                        )
                                    : null,
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
                        ])),
            ],
          ),
        ),
        DragTarget<IntakeEntity>(
          onAcceptWithDetails: (intake) {
            _onItemDropped(intake.data);
          },
          builder: (context, candidateData, rejectedData) {
            return Column(
              children: [
                for (final intakeEntity in widget.intakeList)
                  LongPressDraggable<IntakeEntity>(
                    key: ValueKey(intakeEntity.id),
                    data: intakeEntity,
                    onDragStarted: () => widget.onItemDragCallback?.call(true),
                    onDragEnd: (_) => widget.onItemDragCallback?.call(false),
                    feedback: Material(
                      color: Colors.transparent,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Opacity(
                          opacity: 0.85,
                          child: IntakeCard(
                            key: ValueKey('fb-${intakeEntity.id}'),
                            intake: intakeEntity,
                            firstListElement: false,
                            usesImperialUnits: widget.usesImperialUnits,
                          ),
                        ),
                      ),
                    ),
                    childWhenDragging: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimens.spacing16,
                        vertical: Dimens.spacing4,
                      ),
                      child: Container(
                        height: 76,
                        decoration: BoxDecoration(
                          color: palette.surfaceMuted,
                          borderRadius: Dimens.borderRadiusM,
                          border: Border.all(
                            color: palette.border,
                            width: Dimens.hairline,
                          ),
                        ),
                      ),
                    ),
                    child: IntakeCard(
                      key: ValueKey(intakeEntity.id),
                      intake: intakeEntity,
                      onItemLongPressed: widget.onItemLongPressedCallback,
                      onItemTapped: widget.onItemTappedCallback,
                      firstListElement: false,
                      usesImperialUnits: widget.usesImperialUnits,
                    ),
                  ),
                PlaceholderCard(
                  day: widget.day,
                  onTap: () => _onPlaceholderCardTapped(context),
                  firstListElement: true,
                  semanticIdentifier: 'add-meal-placeholder',
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSortMenu(BuildContext context) {
    final current = widget.sortType ?? DiarySortType.timeAdded;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    return Semantics(
      identifier: 'diary-section-sort-menu',
      child: PopupMenuButton<DiarySortType>(
        tooltip: S.of(context).diarySortByLabel,
        icon: Icon(Icons.sort_rounded, color: palette.textMuted),
        shape: Dimens.shapeM,
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
