import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_card.dart';
import 'package:opennutritracker/core/presentation/widgets/placeholder_card.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_screen.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class IntakeVerticalList extends StatefulWidget {
  final DateTime day;
  final String title;
  final IconData listIcon;
  final AddMealType addMealType;
  final List<IntakeEntity> intakeList;
  final bool usesImperialUnits;
  final Function(BuildContext, IntakeEntity)? onItemLongPressedCallback;
  final Function(bool)? onItemDragCallback;
  final Function(BuildContext, IntakeEntity, bool)? onItemTappedCallback;

  const IntakeVerticalList(
      {super.key,
      required this.day,
      required this.title,
      required this.listIcon,
      required this.addMealType,
      required this.intakeList,
      required this.usesImperialUnits,
      this.onItemLongPressedCallback,
      this.onItemDragCallback,
      this.onItemTappedCallback});

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
              if (totalKcal > 0)
                Text(
                  '${totalKcal.toInt()} ${S.of(context).kcalLabel}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7)),
                ),
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
