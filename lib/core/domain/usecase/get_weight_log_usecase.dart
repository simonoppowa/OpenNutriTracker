import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';

class GetWeightLogUsecase {
  final WeightLogRepository _weightLogRepository;

  GetWeightLogUsecase(this._weightLogRepository);

  Future<List<WeightLogEntity>> getAllEntries() async {
    return _weightLogRepository.getAllEntries();
  }

  Future<List<WeightLogEntity>> getEntriesInRange(
    DateTime from,
    DateTime to,
  ) async {
    return _weightLogRepository.getEntriesInRange(from, to);
  }
}
