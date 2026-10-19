import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/repository/water_intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/water_intake_entity.dart';
import 'package:opennutritracker/core/domain/usecase/delete_water_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_water_intake_usecase.dart';
import 'package:opennutritracker/features/home/domain/day_water_log.dart';

class _FakeRepository implements WaterIntakeRepository {
  final entries = <WaterIntakeEntity>[];
  (DateTime, DateTime)? lastRange;

  @override
  Future<List<WaterIntakeEntity>> getEntriesInRange(
    DateTime from,
    DateTime to,
  ) async {
    lastRange = (from, to);
    return [
      for (final e in entries)
        if (!e.dateTime.isBefore(from) && e.dateTime.isBefore(to)) e,
    ];
  }

  @override
  Future<void> deleteEntry(String id) async =>
      entries.removeWhere((e) => e.id == id);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

void main() {
  late _FakeRepository repository;
  late DayWaterLog log;
  var changes = 0;

  setUp(() {
    repository = _FakeRepository()
      ..entries.addAll([
        WaterIntakeEntity(
          id: 'b',
          dateTime: DateTime(2026, 10, 19, 14),
          amountMl: 500,
        ),
        WaterIntakeEntity(
          id: 'a',
          dateTime: DateTime(2026, 10, 19, 8),
          amountMl: 250,
        ),
        WaterIntakeEntity(
          id: 'c',
          dateTime: DateTime(2026, 10, 20, 2),
          amountMl: 330,
        ),
      ]);
    changes = 0;
    log = DayWaterLog(
      GetWaterIntakeUsecase(repository),
      DeleteWaterIntakeUsecase(repository),
      dayStartOffsetMinutes: () async => 0,
      onChanged: () => changes++,
    );
  });

  test('lists a day\'s entries in the order they were drunk', () async {
    final entries = await log.entriesFor(DateTime(2026, 10, 19));

    expect(entries.map((e) => e.id), ['a', 'b']);
  });

  test('a later day start moves early entries to the day before', () async {
    log = DayWaterLog(
      GetWaterIntakeUsecase(repository),
      DeleteWaterIntakeUsecase(repository),
      dayStartOffsetMinutes: () async => 4 * 60,
      onChanged: () {},
    );

    final entries = await log.entriesFor(DateTime(2026, 10, 19));

    expect(entries.map((e) => e.id), ['a', 'b', 'c']);
    expect(await log.entriesFor(DateTime(2026, 10, 20)), isEmpty);
  });

  test('deleting removes that entry and announces the change', () async {
    final before = log.revision.value;

    await log.delete('b');

    expect(repository.entries.map((e) => e.id), ['a', 'c']);
    expect(log.revision.value, before + 1);
    expect(changes, 1);
  });

  test('a change logged elsewhere bumps the revision', () {
    final before = log.revision.value;

    log.markChanged();

    expect(log.revision.value, before + 1);
    expect(changes, 0);
  });
}
