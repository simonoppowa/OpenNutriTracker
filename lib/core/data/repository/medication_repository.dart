import 'package:opennutritracker/core/data/data_source/medication_data_source.dart';
import 'package:opennutritracker/core/data/dbo/medication_dbo.dart';
import 'package:opennutritracker/core/domain/entity/medication_entity.dart';

class MedicationRepository {
  final MedicationDataSource _dataSource;

  MedicationRepository(this._dataSource);

  Future<void> addEntry(MedicationEntity entity) async {
    await _dataSource.addEntry(MedicationDBO.fromMedicationEntity(entity));
  }

  Future<List<MedicationEntity>> getEntriesForDay(DateTime day) async {
    final dbos = await _dataSource.entriesForDay(day);
    return dbos.map(MedicationEntity.fromMedicationDBO).toList();
  }

  Future<void> deleteEntry(String id) async {
    await _dataSource.deleteEntry(id);
  }

  Future<List<MedicationDBO>> getAllMedicationsDBO() async {
    return await _dataSource.allEntries();
  }

  Future<void> addAllEntries(List<MedicationDBO> entries) async {
    await _dataSource.addAllEntries(entries);
  }

  Future<void> toggleTaken(String id) async {
    final dbo = await _dataSource.getEntry(id);
    if (dbo != null) {
      dbo.taken = !dbo.taken;
      await dbo.save();
    }
  }
}
