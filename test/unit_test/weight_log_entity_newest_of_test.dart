import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';

void main() {
  group('WeightLogEntity.newestOf across a date-line jump', () {
    // An imported entry filed on Jan 1 west of the date line, then a manual
    // entry filed on Jan 2 east of it. Their stored local-midnight instants
    // read back in the wrong order: the imported row's date shows later than
    // the manual one's, although its storage key is a day earlier.
    final imported = WeightLogEntity(
      date: DateTime(2026, 1, 2, 2),
      weightKg: 81,
      externalId: 'scale-1',
      measuredAt: DateTime(2026, 1, 2, 1),
      filedDay: DateTime(2026, 1, 1),
    );
    final manual = WeightLogEntity(
      date: DateTime(2026, 1, 2),
      weightKg: 79,
      filedDay: DateTime(2026, 1, 2),
    );

    test('a manual entry filed on a later day stays newest', () {
      expect(WeightLogEntity.newestOf([imported, manual]), manual);
      expect(WeightLogEntity.newestOf([manual, imported]), manual);
    });

    test('of two manual entries, the later filed day wins', () {
      final earlierKey = WeightLogEntity(
        date: DateTime(2026, 1, 2, 2),
        weightKg: 80,
        filedDay: DateTime(2026, 1, 1),
      );
      expect(WeightLogEntity.newestOf([earlierKey, manual]), manual);
    });

    test('an entry not read from the log still falls back to its date', () {
      final later = WeightLogEntity(
        date: DateTime(2026, 1, 3),
        weightKg: 82,
        externalId: 'scale-2',
        measuredAt: DateTime(2026, 1, 3, 7),
      );
      expect(WeightLogEntity.newestOf([manual, later]), later);
    });
  });
}
