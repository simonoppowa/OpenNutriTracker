import 'package:opennutritracker/features/fasting/data/repository/fasting_repository.dart';
import 'package:opennutritracker/features/fasting/domain/entity/fasting_session_entity.dart';

/// Records a neutral, unjudged end to the session. The framing is deliberate:
/// there is no "broken streak" concept, no "fast ended early" copy, and no
/// stored boolean for "was the goal met". The presence of `cancelledAt` is the
/// only signal that the user closed the session themselves.
class CancelFastingUseCase {
  final FastingRepository _repository;

  CancelFastingUseCase(this._repository);

  Future<FastingSessionEntity> call(
    FastingSessionEntity session, {
    DateTime? now,
  }) async {
    final updated = session.copyWith(cancelledAt: now ?? DateTime.now());
    await _repository.updateSession(updated);
    return updated;
  }
}
