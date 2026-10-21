import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';

class DeleteIntakeUsecase {
  final IntakeRepository _intakeRepository;

  /// Told after every deleted entry, so a meal reminder can come back (#72).
  final void Function()? _onChanged;

  DeleteIntakeUsecase(this._intakeRepository, {void Function()? onChanged})
    : _onChanged = onChanged;

  Future<void> deleteIntake(IntakeEntity intakeEntity) async {
    await _intakeRepository.deleteIntake(intakeEntity);
    _onChanged?.call();
  }
}
