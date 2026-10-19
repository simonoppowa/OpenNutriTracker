import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/features/body_measurements/domain/body_measurement.dart';

/// The active profile's body measurements in `BodyMeasurementBox`, one JSON
/// entry per id.
class BodyMeasurementDataSource {
  static final _log = Logger('BodyMeasurementDataSource');

  final HiveDBProvider _db;

  BodyMeasurementDataSource(this._db);

  /// Every measurement, newest first; an unreadable entry is skipped.
  List<BodyMeasurement> all() {
    final measurements = <BodyMeasurement>[];
    for (final raw in _db.bodyMeasurementBox.values) {
      try {
        measurements.add(
          BodyMeasurement.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        );
      } on Object catch (error) {
        _log.warning('Skipping an unreadable body measurement', error);
      }
    }
    return measurements..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> put(BodyMeasurement measurement) => _db.bodyMeasurementBox.put(
    measurement.id,
    jsonEncode(measurement.toJson()),
  );

  Future<void> putAll(Iterable<BodyMeasurement> measurements) => _db
      .bodyMeasurementBox
      .putAll({for (final m in measurements) m.id: jsonEncode(m.toJson())});

  Future<void> delete(String id) => _db.bodyMeasurementBox.delete(id);
}
