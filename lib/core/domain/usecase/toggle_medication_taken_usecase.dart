import 'package:opennutritracker/core/data/repository/medication_repository.dart';

class ToggleMedicationTakenUsecase {
  final MedicationRepository _repository;

  ToggleMedicationTakenUsecase(this._repository);

  Future<void> toggleTaken(String id) async {
    await _repository.toggleTaken(id);
  }
}
