import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/features/body_measurements/data/body_measurement_data_source.dart';
import 'package:opennutritracker/features/body_measurements/domain/body_measurement.dart';
import 'package:opennutritracker/features/body_measurements/domain/body_measurements_usecase.dart';

import '../../helpers/fake_hive_db_provider.dart';

void main() {
  late Directory dir;
  late Box<String> box;
  late BodyMeasurementsUsecase measurements;
  var ids = 0;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('body_measurements_test');
    Hive.init(dir.path);
    box = await Hive.openBox<String>('body');
    ids = 0;
    measurements = BodyMeasurementsUsecase(
      BodyMeasurementDataSource(FakeHiveDBProvider(bodyMeasurementBox: box)),
      newId: () => 'm${++ids}',
    );
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('every measure is optional, one is enough', () async {
    final m = await measurements.add(
      date: DateTime(2026, 10, 1),
      valuesCm: {BodyMeasureKind.waist: 84.5},
    );

    expect(m[BodyMeasureKind.waist], 84.5);
    expect(m[BodyMeasureKind.chest], isNull);
    expect(measurements.list(), [m]);
  });

  test('a measurement without any value is refused', () async {
    expect(
      () => measurements.add(date: DateTime(2026, 10, 1), valuesCm: {}),
      throwsArgumentError,
    );
    expect(measurements.list(), isEmpty);
  });

  test('values out of range are refused', () async {
    expect(
      () => measurements.add(
        date: DateTime(2026, 10, 1),
        valuesCm: {BodyMeasureKind.arm: 3},
      ),
      throwsArgumentError,
    );
  });

  test('the list is newest first, a series oldest first', () async {
    await measurements.add(
      date: DateTime(2026, 9, 1),
      valuesCm: {BodyMeasureKind.waist: 88, BodyMeasureKind.hip: 100},
    );
    await measurements.add(
      date: DateTime(2026, 10, 1),
      valuesCm: {BodyMeasureKind.waist: 85},
    );

    expect(measurements.list().map((m) => m.id), ['m2', 'm1']);
    expect(measurements.seriesOf(BodyMeasureKind.waist), [
      (date: DateTime(2026, 9, 1), cm: 88.0),
      (date: DateTime(2026, 10, 1), cm: 85.0),
    ]);
    expect(measurements.seriesOf(BodyMeasureKind.hip), hasLength(1));
  });

  test(
    'editing replaces, deleting removes, each change is announced',
    () async {
      final m = await measurements.add(
        date: DateTime(2026, 10, 1),
        valuesCm: {BodyMeasureKind.waist: 85},
      );
      final before = measurements.changes.value;

      await measurements.update(
        BodyMeasurement(
          id: m.id,
          date: m.date,
          valuesCm: {BodyMeasureKind.waist: 84, BodyMeasureKind.thigh: 58},
          note: 'morning',
        ),
      );
      expect(measurements.list().single[BodyMeasureKind.thigh], 58);
      expect(measurements.list().single.note, 'morning');

      await measurements.delete(m.id);
      expect(measurements.list(), isEmpty);
      expect(measurements.changes.value, before + 2);
    },
  );

  test('a measurement round-trips through JSON and bad JSON is refused', () {
    final m = BodyMeasurement(
      id: 'x',
      date: DateTime(2026, 10, 1),
      valuesCm: {BodyMeasureKind.chest: 101.5, BodyMeasureKind.arm: 34},
      note: null,
    );

    expect(BodyMeasurement.fromJson(m.toJson()), m);
    expect(
      () => BodyMeasurement.fromJson(const {
        'id': 'x',
        'date': '2026-10-01T00:00:00.000',
      }),
      throwsFormatException,
    );
    expect(
      () => BodyMeasurement.fromJson(const {
        'id': 'x',
        'date': '2026-10-01T00:00:00.000',
        'waistCm': 2000,
      }),
      throwsFormatException,
    );
    expect(
      () => BodyMeasurement.fromJson(const {
        'id': ' ',
        'date': '2026-10-01T00:00:00.000',
        'waistCm': 80,
      }),
      throwsFormatException,
    );
  });

  test('an unreadable stored entry is skipped', () async {
    await box.put('broken', 'nope');
    await measurements.add(
      date: DateTime(2026, 10, 1),
      valuesCm: {BodyMeasureKind.waist: 85},
    );

    expect(measurements.list(), hasLength(1));
  });
}
