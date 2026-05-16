import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/features/fasting/data/repository/fasting_repository.dart';
import 'package:opennutritracker/features/fasting/domain/entity/fasting_session_entity.dart';

class StartFastingUseCase {
  final FastingRepository _repository;

  StartFastingUseCase(this._repository);

  Future<FastingSessionEntity> call({
    required int targetDurationMinutes,
    DateTime? now,
  }) async {
    final session = FastingSessionEntity(
      id: IdGenerator.getUniqueID(),
      startedAt: now ?? DateTime.now(),
      targetDurationMinutes: targetDurationMinutes,
    );
    await _repository.addSession(session);
    return session;
  }
}
