import 'package:opennutritracker/core/data/repository/config_repository.dart';

/// Persists the user's one-time acknowledgement of the disordered-eating
/// sensitivity warning. Once acknowledged, the warning dialog stays
/// suppressed on subsequent visits to the fasting screen.
class AcknowledgeFastingWarningUseCase {
  final ConfigRepository _configRepository;

  AcknowledgeFastingWarningUseCase(this._configRepository);

  Future<void> call() async {
    await _configRepository.setFastingWarningAcknowledged(true);
  }
}
