import 'package:flutter/foundation.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/features/body_measurements/data/body_measurement_data_source.dart';
import 'package:opennutritracker/features/body_measurements/domain/body_measurement.dart';

/// Recording, changing and listing body measurements (#43).
class BodyMeasurementsUsecase {
  final BodyMeasurementDataSource _dataSource;
  final String Function() _newId;

  /// Goes up whenever the measurements changed, so open screens update.
  final ValueNotifier<int> changes = ValueNotifier(0);

  BodyMeasurementsUsecase(this._dataSource, {String Function()? newId})
    : _newId = newId ?? IdGenerator.getUniqueID;

  /// Newest first.
  List<BodyMeasurement> list() => _dataSource.all();

  /// The measurements that hold [kind], oldest first, for a chart.
  List<({DateTime date, double cm})> seriesOf(BodyMeasureKind kind) => [
    for (final m in list().reversed)
      if (m[kind] case final cm?) (date: m.date, cm: cm),
  ];

  /// Records a new measurement; throws an [ArgumentError] without any
  /// value or with one out of range.
  Future<BodyMeasurement> add({
    required DateTime date,
    required Map<BodyMeasureKind, double> valuesCm,
    String? note,
  }) async {
    final measurement = BodyMeasurement(
      id: _newId(),
      date: date,
      valuesCm: valuesCm,
      note: note,
    );
    await _dataSource.put(measurement);
    changes.value++;
    return measurement;
  }

  Future<void> update(BodyMeasurement measurement) async {
    await _dataSource.put(measurement);
    changes.value++;
  }

  Future<void> delete(String id) async {
    await _dataSource.delete(id);
    changes.value++;
  }
}
