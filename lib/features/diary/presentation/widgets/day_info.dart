import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

class DayInfo extends StatelessWidget {
  final DateTime selectedDay;
  final TrackedDayEntity? trackedDayEntity;

  const DayInfo(
      {Key? key, required this.selectedDay, required this.trackedDayEntity})
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
              : Text(S.of(context).nothingAddedLabel)
        ],
      ),
    );
  }
}
