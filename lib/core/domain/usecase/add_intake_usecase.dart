import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';

class AddIntakeUsecase {
  final IntakeRepository _intakeRepository;

  /// Told after every added entry, so meal reminders can leave out today's
  /// once the meal is logged (#72).
  final void Function()? _onChanged;

  AddIntakeUsecase(this._intakeRepository, {void Function()? onChanged})
    : _onChanged = onChanged;

  Future<void> addIntake(IntakeEntity intakeEntity) async {
    await _intakeRepository.addIntake(intakeEntity);
    _onChanged?.call();
  }
}
