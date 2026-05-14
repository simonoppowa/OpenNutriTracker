import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';

class DeleteWeightLogUsecase {
  final WeightLogRepository _weightLogRepository;

  DeleteWeightLogUsecase(this._weightLogRepository);

  Future<void> deleteEntry(DateTime date) async {
    await _weightLogRepository.deleteEntry(date);
  }
}
