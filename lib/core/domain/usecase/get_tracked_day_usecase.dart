import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';

class GetTrackedDayUsecase {
  final TrackedDayRepository _trackedDayRepository;

  GetTrackedDayUsecase(this._trackedDayRepository);

  Future<TrackedDayEntity?> getTrackedDay(DateTime day) async {
    return await _trackedDayRepository.getTrackedDay(day);
  }

  Future<List<TrackedDayEntity>> getTrackedDaysByRange(
      DateTime start, DateTime end) {
    return _trackedDayRepository.getTrackedDayByRange(start, end);
  }
}
