import 'package:opennutritracker/core/data/repository/medication_repository.dart';

class DeleteMedicationUsecase {
  final MedicationRepository _repository;

  DeleteMedicationUsecase(this._repository);

  Future<void> deleteEntry(String id) async {
    await _repository.deleteEntry(id);
  }
}
