import 'package:opennutritracker/core/data/repository/medication_repository.dart';
import 'package:opennutritracker/core/domain/entity/medication_entity.dart';

class GetMedicationUsecase {
  final MedicationRepository _repository;

  GetMedicationUsecase(this._repository);

  Future<List<MedicationEntity>> getEntriesForDay(DateTime day) async {
    return await _repository.getEntriesForDay(day);
  }
}
