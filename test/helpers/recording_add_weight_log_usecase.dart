import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_weight_log_usecase.dart';

/// Records the weight readings it is asked to add, and stores nothing.
class RecordingAddWeightLogUsecase extends Fake implements AddWeightLogUsecase {
  final entries = <WeightLogEntity>[];

  @override
  Future<void> addEntry(WeightLogEntity entry) async => entries.add(entry);
}
