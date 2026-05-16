import 'package:opennutritracker/features/fasting/data/repository/fasting_repository.dart';
import 'package:opennutritracker/features/fasting/domain/entity/fasting_session_entity.dart';

/// Marks the session as having reached its target duration. Stored on its own
/// timestamp field (`completedAt`) so the cancellation path and the natural
/// completion path are recorded as different facts, without one being framed
/// as success and the other as failure.
class CompleteFastingUseCase {
  final FastingRepository _repository;

  CompleteFastingUseCase(this._repository);

  Future<FastingSessionEntity> call(
    FastingSessionEntity session, {
    DateTime? now,
  }) async {
    final updated = session.copyWith(completedAt: now ?? DateTime.now());
    await _repository.updateSession(updated);
    return updated;
  }
}
