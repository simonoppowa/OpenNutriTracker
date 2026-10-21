import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';

class UpdateIntakeUsecase {
  final IntakeRepository _intakeRepository;

  /// Told after every changed entry, which can move it to another meal or
  /// day (#72).
  final void Function()? _onChanged;

  UpdateIntakeUsecase(this._intakeRepository, {void Function()? onChanged})
    : _onChanged = onChanged;

  Future<IntakeEntity?> updateIntake(
    String intakeId,
    Map<String, dynamic> intakeFields,
  ) async {
    final updated = await _intakeRepository.updateIntake(
      intakeId,
      intakeFields,
    );
    _onChanged?.call();
    return updated;
  }
}
