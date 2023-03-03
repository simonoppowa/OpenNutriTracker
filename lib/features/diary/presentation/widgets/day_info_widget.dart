import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/activity_vertial_list.dart';
import 'package:opennutritracker/features/home/presentation/widgets/meal_Intake_list.dart';
import 'package:opennutritracker/generated/l10n.dart';

class DayInfoWidget extends StatelessWidget {
  final DateTime selectedDay;
  final TrackedDayEntity? trackedDayEntity;
  final List<UserActivityEntity> userActivities;
  final List<IntakeEntity> breakfastIntake;
  final List<IntakeEntity> lunchIntake;
  final List<IntakeEntity> dinnerIntake;
  final List<IntakeEntity> snackIntake;

  const DayInfoWidget(
      {Key? key,
      required this.selectedDay,
      required this.trackedDayEntity,
      required this.userActivities,
      required this.breakfastIntake,
      required this.lunchIntake,
      required this.dinnerIntake,
      required this.snackIntake})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat.yMMMMEEEEd().format(selectedDay),
              style: Theme.of(context).textTheme.headline5),
          const SizedBox(height: 16.0),
          trackedDayEntity != null
              ? Text(
                  '${trackedDayEntity?.caloriesTracked.toInt()}/${trackedDayEntity?.calorieGoal.toInt()} kcal',
                  style: Theme.of(context)
                      .textTheme
                      .headline6
                      ?.copyWith(fontWeight: FontWeight.bold),
                )
              : Text(S.of(context).nothingAddedLabel),
          const SizedBox(height: 8.0),
          userActivities.isNotEmpty
              ? ActivityVerticalList(
                  title: S.of(context).activityLabel,
                  userActivityList: userActivities,
                  onItemLongPressedCallback: onActivityItemLongPressed)
              : const SizedBox(),
          breakfastIntake.isNotEmpty
              ? MealIntakeList(
                  title: S.of(context).breakfastLabel,
                  listIcon: Icons.bakery_dining_outlined,
                  intakeList: breakfastIntake,
                  onItemLongPressedCallback: onIntakeItemLongPressed,
                )
              : const SizedBox(),
          lunchIntake.isNotEmpty
              ? MealIntakeList(
                  title: S.of(context).lunchLabel,
                  listIcon: Icons.lunch_dining_outlined,
                  intakeList: lunchIntake,
                  onItemLongPressedCallback: onIntakeItemLongPressed,
                )
              : const SizedBox(),
          dinnerIntake.isNotEmpty
              ? MealIntakeList(
                  title: S.of(context).dinnerLabel,
                  listIcon: Icons.dinner_dining_outlined,
                  intakeList: dinnerIntake,
                  onItemLongPressedCallback: onIntakeItemLongPressed,
                )
              : const SizedBox(),
          snackIntake.isNotEmpty
              ? MealIntakeList(
                  title: S.of(context).snackLabel,
                  listIcon: Icons.icecream_outlined,
                  intakeList: snackIntake,
                  onItemLongPressedCallback: onIntakeItemLongPressed,
                )
              : const SizedBox()
        ],
      ),
    );
  }

  void onIntakeItemLongPressed(
      BuildContext context, IntakeEntity intakeEntity) async {
    // TODO
  }

  void onActivityItemLongPressed(
      BuildContext context, UserActivityEntity activityEntity) async {
    // TODO
  }
}
