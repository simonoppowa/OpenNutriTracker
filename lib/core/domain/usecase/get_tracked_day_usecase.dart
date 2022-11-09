import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:provider/provider.dart';

class GetTrackedDayUsecase {
  Future<TrackedDayEntity?> getTrackedDay(BuildContext context, DateTime day) {
    final trackedDayRepository =
        Provider.of<TrackedDayRepository>(context, listen: false);
    return trackedDayRepository.getTrackedDay(day);
  }

  Future<List<TrackedDayEntity>> getTrackedDaysByRange(
      BuildContext context, DateTime start, DateTime end) {
    final trackedDayRepository =
        Provider.of<TrackedDayRepository>(context, listen: false);
    return trackedDayRepository.getTrackedDayByRange(start, end);
  }
}
