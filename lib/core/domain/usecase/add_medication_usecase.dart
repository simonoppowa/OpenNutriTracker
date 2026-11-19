import 'package:opennutritracker/core/data/repository/medication_repository.dart';
import 'package:opennutritracker/core/domain/entity/medication_entity.dart';

class AddMedicationUsecase {
  final MedicationRepository _repository;

  AddMedicationUsecase(this._repository);

  Future<void> addEntry(MedicationEntity entity) async {
    await _repository.addEntry(entity);
  }
}
