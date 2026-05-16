import 'package:opennutritracker/features/fasting/data/repository/fasting_repository.dart';
import 'package:opennutritracker/features/fasting/domain/entity/fasting_session_entity.dart';

class GetActiveFastingSessionUseCase {
  final FastingRepository _repository;

  GetActiveFastingSessionUseCase(this._repository);

  Future<FastingSessionEntity?> call() => _repository.getActiveSession();
}
