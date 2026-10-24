import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_weight_log_usecase.dart';

/// Records the weight readings it is asked to add, and stores nothing — so
/// it reports the current weight as unchanged.
class RecordingAddWeightLogUsecase extends Fake implements AddWeightLogUsecase {
  final entries = <WeightLogEntity>[];

  @override
  Future<bool> addEntry(WeightLogEntity entry) async {
    entries.add(entry);
    return false;
  }
}
