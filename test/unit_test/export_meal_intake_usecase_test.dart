import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/health/external_meal_intake.dart';
import 'package:opennutritracker/core/data/data_source/health/noop_health_service.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/health_export_diary_repository.dart';
import 'package:opennutritracker/core/data/repository/health_export_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/export_meal_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

/// The health store, as a log of what reached it.
class _FakeHealthExportRepository extends Fake
    implements HealthExportRepository {
  /// Health Connect (true) or HealthKit (false).
  bool identity = true;
  bool deleteResult = true;
  bool shouldThrow = false;

  /// A record id whose write throws.
  String? throwFor;

  /// How many more times each record id's write reports failure.
  final Map<String, int> failingWrites = {};

  /// While set, writes wait for it: holds an operation in flight.
  Completer<void>? writeGate;

  /// Deletes and writes in the order they reached the store.
  final List<String> ops = [];
  final List<ExternalMealIntake> writtenMeals = [];

  @override
  bool get hasRecordIdentity => identity;

  @override
  Future<bool> writeMeal(ExternalMealIntake intake) async {
    if (shouldThrow || intake.id == throwFor) {
      throw Exception('Platform channel error');
    }
    await writeGate?.future;
    final failuresLeft = failingWrites[intake.id] ?? 0;
    if (failuresLeft > 0) {
      failingWrites[intake.id] = failuresLeft - 1;
      return false;
    }
    writtenMeals.add(intake);
    ops.add('write ${intake.id}');
    return true;
  }

  @override
  Future<bool> deleteMeal(String clientRecordId) async {
    if (shouldThrow) throw Exception('Platform channel error');
    ops.add('delete $clientRecordId');
    return deleteResult;
  }

  @override
  Future<bool> deleteMealWindow(DateTime start) async {
    if (shouldThrow) throw Exception('Platform channel error');
    ops.add('delete window $start');
    return deleteResult;
  }
}

/// Every profile's diary and opt-in, with the repository's snapshot rules.
class _FakeDiaryRepository extends Fake
    implements HealthExportDiaryRepository {
  @override
  String activeProfileId = 'a';

  /// Each profile's stored opt-in; a missing profile never opted in.
  final Map<String, bool?> optIn = {'a': true};
  final Map<String, List<IntakeEntity>> diaries = {'a': []};

  /// Makes a snapshot fail as a profile switch during it would.
  bool switchDuringSnapshot = false;

  @override
  Future<bool> isExportEnabled(String profileId) async =>
      optIn[profileId] ?? false;

  /// Makes [readProfile] fail.
  bool failReadProfile = false;

  @override
  Future<ProfileDiary?> readProfile(String profileId) async {
    if (failReadProfile) throw StateError('box closed');
    if (!diaries.containsKey(profileId)) return null;
    return ProfileDiary(
      exportEnabled: optIn[profileId],
      intakes: List.of(diaries[profileId]!),
    );
  }

  @override
  Future<ExportWindowSnapshot> snapshotWindows(
    Set<DateTime> starts,
    Duration length, {
    String? exceptProfile,
  }) async {
    if (switchDuringSnapshot) throw StateError('profile switched');
    bool inside(IntakeEntity intake) => starts.any(
      (start) =>
          !intake.dateTime.isBefore(start) &&
          intake.dateTime.isBefore(start.add(length)),
    );
    List<IntakeEntity> entriesWhere(bool? flag) => [
      for (final MapEntry(key: id, value: entries) in diaries.entries)
        if (id != exceptProfile && optIn[id] == flag) ...entries.where(inside),
    ];
    return ExportWindowSnapshot(
      exported: entriesWhere(true),
      optedOut: entriesWhere(false),
    );
  }
}

/// The persisted pending sets, in memory.
class _FakeConfigRepository extends Fake implements ConfigRepository {
  Set<DateTime> pending = {};
  Set<String> pendingDeletes = {};

  @override
  Future<Set<DateTime>> getHealthPendingExportWindows() async => {...pending};

  @override
  Future<void> updateHealthPendingExportWindows({
    Set<DateTime> add = const {},
    Set<DateTime> remove = const {},
  }) async => pending = {...pending, ...add}..removeAll(remove);

  @override
  Future<Set<String>> getHealthPendingRecordDeletes() async => {
    ...pendingDeletes,
  };

  @override
  Future<void> updateHealthPendingRecordDeletes({
    Set<String> add = const {},
    Set<String> remove = const {},
  }) async => pendingDeletes = {...pendingDeletes, ...add}..removeAll(remove);
}

class _FakeIntakeRepository extends Fake implements IntakeRepository {
  final List<IntakeEntity> addedIntakes = [];
  final List<IntakeEntity> deletedIntakes = [];
  IntakeEntity? updatedIntakeResult;

  /// What the repository holds.
  List<IntakeEntity> storedIntakes = [];

  @override
  Future<void> addIntake(IntakeEntity intakeEntity) async {
    addedIntakes.add(intakeEntity);
  }

  @override
  Future<void> deleteIntake(IntakeEntity intakeEntity) async {
    deletedIntakes.add(intakeEntity);
  }

  @override
  Future<IntakeEntity?> getIntakeById(String intakeId) async =>
      storedIntakes.where((intake) => intake.id == intakeId).firstOrNull;

  /// Stores [updatedIntakeResult] in place of the intake it edits, as the
  /// real repository does.
  @override
  Future<IntakeEntity?> updateIntake(
    String intakeId,
    Map<String, dynamic> fields,
  ) async {
    final result = updatedIntakeResult;
    if (result != null) {
      storedIntakes = [
        for (final intake in storedIntakes)
          if (intake.id == intakeId) result else intake,
      ];
    }
    return result;
  }
}

void main() {
  final mealDate = DateTime(2026, 6, 15, 12, 30);
  final testIntake = IntakeEntity(
    id: 'intake-123',
    unit: 'g',
    amount: 150, // 150g -> scale factor 1.5
    type: IntakeTypeEntity.lunch,
    dateTime: mealDate,
    meal: const MealEntity(
      code: 'code-abc',
      name: 'Granola & Yogurt',
      url: null,
      mealQuantity: '100',
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: 'g',
      servingSize: '100 g',
      source: MealSourceEntity.off,
      nutriments: MealNutrimentsEntity(
        energyKcal100: 200, // * 1.5 = 300 kcal
        carbohydrates100: 30, // * 1.5 = 45 g
        fat100: 10, // * 1.5 = 15 g
        proteins100: 8, // * 1.5 = 12 g
        saturatedFat100: 2, // * 1.5 = 3 g
        sugars100: 12, // * 1.5 = 18 g
        fiber100: 4, // * 1.5 = 6 g
        sodium100: 100, // 100mg * 1.5 = 150mg -> 0.15 g
        calcium100: 200, // 200mg * 1.5 = 300mg -> 0.3 g
        potassium100: 300, // 300mg * 1.5 = 450mg -> 0.45 g
        cholesterol100: 20, // 20mg * 1.5 = 30mg -> 0.03 g
        vitaminD100: 2, // 2µg * 1.5 = 3µg -> 3e-6 g
      ),
    ),
  );

  group('ExternalMealIntake mapping', () {
    test('scales calories and converts micronutrient units properly', () {
      final external = ExternalMealIntake.fromIntake(testIntake);

      expect(external.id, equals('ont_intake_intake-123'));
      expect(external.name, equals('Granola & Yogurt'));
      expect(external.mealTypeName, equals('LUNCH'));
      expect(external.dateTime, equals(mealDate));
      expect(external.calories, closeTo(300.0, 0.01));
      expect(external.carbohydrates, closeTo(45.0, 0.01));
      expect(external.fatTotal, closeTo(15.0, 0.01));
      expect(external.protein, closeTo(12.0, 0.01));
      expect(external.fatSaturated, closeTo(3.0, 0.01));
      expect(external.sugar, closeTo(18.0, 0.01));
      expect(external.fiber, closeTo(6.0, 0.01));
      // Milligrams to grams conversion
      expect(external.sodium, closeTo(0.15, 0.001));
      expect(external.calcium, closeTo(0.3, 0.001));
      expect(external.potassium, closeTo(0.45, 0.001));
      expect(external.cholesterol, closeTo(0.03, 0.001));
      // Micrograms to grams conversion
      expect(external.vitaminD, closeTo(3e-6, 1e-8));
    });

    // #1393 review: IntakeEntity's totals read a missing value as 0.
    test('omits calories and macros the food does not list', () {
      final unknown = IntakeEntity(
        id: 'intake-unknown',
        unit: 'g',
        amount: 150,
        type: IntakeTypeEntity.snack,
        dateTime: mealDate,
        meal: const MealEntity(
          code: null,
          name: 'Mystery bar',
          url: null,
          mealQuantity: '100',
          mealUnit: 'g',
          servingQuantity: null,
          servingUnit: 'g',
          servingSize: '100 g',
          source: MealSourceEntity.custom,
          nutriments: MealNutrimentsEntity(
            energyKcal100: null,
            carbohydrates100: 30,
            fat100: null,
            proteins100: null,
            sugars100: null,
            saturatedFat100: null,
            fiber100: null,
          ),
        ),
      );

      final external = ExternalMealIntake.fromIntake(unknown);

      expect(external.calories, isNull);
      expect(external.fatTotal, isNull);
      expect(external.protein, isNull);
      expect(external.carbohydrates, closeTo(45.0, 0.01));
    });
  });

  IntakeEntity edit(
    IntakeEntity intake, {
    double? amount,
    DateTime? dateTime,
    String? id,
  }) => IntakeEntity(
    id: id ?? intake.id,
    unit: intake.unit,
    amount: amount ?? intake.amount,
    type: intake.type,
    meal: intake.meal,
    dateTime: dateTime ?? intake.dateTime,
  );

  late _FakeHealthExportRepository healthRepo;
  late _FakeDiaryRepository diary;
  late _FakeConfigRepository config;
  late ExportMealIntakeUsecase usecase;

  setUp(() {
    healthRepo = _FakeHealthExportRepository();
    diary = _FakeDiaryRepository();
    config = _FakeConfigRepository();
    usecase = ExportMealIntakeUsecase(
      healthRepo,
      diary,
      config,
      retryDelay: Duration.zero,
    );
  });

  group('ExportMealIntakeUsecase on Health Connect', () {
    test('does nothing when the profile has not opted in', () async {
      diary.optIn['a'] = false;

      expect(await usecase.exportIntake(testIntake), isFalse);
      expect(await usecase.deleteIntake(testIntake), isFalse);
      expect(
        await usecase.exportUpdatedIntake(testIntake, testIntake),
        isFalse,
      );

      expect(healthRepo.ops, isEmpty);
    });

    test('writes, rewrites and deletes by record id', () async {
      final after = edit(testIntake, amount: 200);

      expect(await usecase.exportIntake(testIntake), isTrue);
      expect(await usecase.exportUpdatedIntake(testIntake, after), isTrue);
      expect(await usecase.deleteIntake(after), isTrue);

      expect(healthRepo.ops, [
        'write ont_intake_intake-123',
        'write ont_intake_intake-123',
        'delete ont_intake_intake-123',
      ]);
      expect(healthRepo.writtenMeals.last.calories, closeTo(400.0, 0.01));
    });

    test('a failed write is retried', () async {
      healthRepo.failingWrites['ont_intake_intake-123'] = 1;

      expect(await usecase.exportIntake(testIntake), isTrue);

      expect(healthRepo.ops, ['write ont_intake_intake-123']);
    });

    test('there is nothing to replay on app start', () async {
      expect(await usecase.replayPendingWindows(), isTrue);

      expect(healthRepo.ops, isEmpty);
    });

    test('a platform error is reported as false without throwing', () async {
      healthRepo.shouldThrow = true;

      expect(await usecase.exportIntake(testIntake), isFalse);
      expect(await usecase.deleteIntake(testIntake), isFalse);
    });
  });

  // #1393 review: exports were fire-and-forget, so a delete could finish
  // before the write it followed and leave a ghost meal behind.
  group('operations run in the order they were requested', () {
    test('a delete waits for the write still in flight', () async {
      healthRepo.writeGate = Completer<void>();

      final write = usecase.exportIntake(testIntake);
      final delete = usecase.deleteIntake(testIntake);
      await Future<void>.delayed(Duration.zero);
      expect(healthRepo.ops, isEmpty);

      healthRepo.writeGate!.complete();
      await Future.wait([write, delete]);

      expect(healthRepo.ops, [
        'write ont_intake_intake-123',
        'delete ont_intake_intake-123',
      ]);
    });

    test('a failed operation does not stall the ones after it', () async {
      healthRepo.throwFor = 'ont_intake_bad';

      final failed = usecase.exportIntake(edit(testIntake, id: 'bad'));
      final next = usecase.exportIntake(testIntake);

      expect(await failed, isFalse);
      expect(await next, isTrue);
      expect(healthRepo.ops, ['write ont_intake_intake-123']);
    });

    test('consent is the requesting profile\'s, not the next one\'s', () async {
      diary.optIn['b'] = false;
      healthRepo.writeGate = Completer<void>();

      final held = usecase.exportIntake(testIntake);
      final queued = usecase.exportIntake(edit(testIntake, id: 'second'));
      // A switch to a profile that never opted in lands mid-queue.
      diary.activeProfileId = 'b';
      healthRepo.writeGate!.complete();
      await Future.wait([held, queued]);

      expect(healthRepo.ops, [
        'write ont_intake_intake-123',
        'write ont_intake_second',
      ]);
      // And what the other profile asks for afterwards stays off.
      expect(await usecase.exportIntake(testIntake), isFalse);
    });
  });

  // HealthKit gets no record id from the plugin, and its only delete clears
  // every meal this app wrote in a minute, from any profile (#1393 review).
  group('ExportMealIntakeUsecase on HealthKit', () {
    setUp(() => healthRepo.identity = false);

    test('an add replaces its window', () async {
      diary.diaries['a'] = [testIntake];

      expect(await usecase.exportIntake(testIntake), isTrue);

      expect(healthRepo.ops, [
        'delete window $mealDate',
        'write ont_intake_intake-123',
      ]);
    });

    test('a delete rewrites a same-minute sibling, not skips', () async {
      final sibling = edit(
        testIntake,
        id: 'sibling',
        dateTime: mealDate.add(const Duration(seconds: 10)),
      );
      // The deleted entry has already left the diary.
      diary.diaries['a'] = [sibling];

      expect(await usecase.deleteIntake(testIntake), isTrue);

      expect(healthRepo.ops, [
        'delete window $mealDate',
        'write ont_intake_sibling',
      ]);
    });

    test('an edit with no siblings replaces only itself', () async {
      final after = edit(testIntake, amount: 200);
      diary.diaries['a'] = [after];

      expect(await usecase.exportUpdatedIntake(testIntake, after), isTrue);

      expect(healthRepo.ops, [
        'delete window $mealDate',
        'write ont_intake_intake-123',
      ]);
      expect(healthRepo.writtenMeals.single.calories, closeTo(400.0, 0.01));
    });

    test('an edit rewrites a same-minute sibling, not loses it', () async {
      final after = edit(testIntake, amount: 200);
      final sibling = edit(
        testIntake,
        id: 'sibling',
        dateTime: mealDate.add(const Duration(seconds: 10)),
      );
      diary.diaries['a'] = [after, sibling];

      await usecase.exportUpdatedIntake(testIntake, after);

      expect(healthRepo.ops.first, 'delete window $mealDate');
      expect(
        healthRepo.ops.skip(1),
        unorderedEquals([
          'write ont_intake_intake-123',
          'write ont_intake_sibling',
        ]),
      );
    });

    test('a moved entry replaces its old and its new window', () async {
      final moved = mealDate.add(const Duration(hours: 2));
      final after = edit(testIntake, dateTime: moved);
      final oldSibling = edit(testIntake, id: 'old', dateTime: mealDate);
      final newSibling = edit(
        testIntake,
        id: 'new',
        dateTime: moved.add(const Duration(seconds: 5)),
      );
      // Starts where the old window ends, so the delete never touched it.
      final outside = edit(
        testIntake,
        id: 'outside',
        dateTime: mealDate.add(const Duration(minutes: 1)),
      );
      diary.diaries['a'] = [after, oldSibling, newSibling, outside];

      await usecase.exportUpdatedIntake(testIntake, after);

      expect(healthRepo.ops, [
        'delete window $mealDate',
        'write ont_intake_old',
        'delete window $moved',
        'write ont_intake_intake-123',
        'write ont_intake_new',
      ]);
    });

    test('nothing is written when a window cannot be deleted', () async {
      final after = edit(testIntake, amount: 200);
      diary.diaries['a'] = [after];
      healthRepo.deleteResult = false;

      expect(await usecase.exportUpdatedIntake(testIntake, after), isFalse);

      expect(healthRepo.writtenMeals, isEmpty);
      expect(config.pending, {mealDate});
    });

    // #1393 review: the window delete had already removed a meal whose
    // rewrite then failed, and nothing ever tried again.
    group('a failed rewrite', () {
      test('is retried, window and all, until it lands', () async {
        diary.diaries['a'] = [testIntake];
        healthRepo.failingWrites['ont_intake_intake-123'] = 2;

        expect(await usecase.exportIntake(testIntake), isTrue);

        expect(healthRepo.ops, [
          'delete window $mealDate',
          'delete window $mealDate',
          'delete window $mealDate',
          'write ont_intake_intake-123',
        ]);
        expect(config.pending, isEmpty);
      });

      // #1393 review: a HealthKit write that failed may have saved part of
      // the meal, so writing it again alone could double it.
      test('a retry clears the window again before rewriting it', () async {
        final sibling = edit(
          testIntake,
          id: 'sibling',
          dateTime: mealDate.add(const Duration(seconds: 10)),
        );
        diary.diaries['a'] = [testIntake, sibling];
        healthRepo.failingWrites['ont_intake_sibling'] = 1;

        expect(await usecase.exportIntake(testIntake), isTrue);

        expect(healthRepo.ops, [
          'delete window $mealDate',
          'write ont_intake_intake-123',
          'delete window $mealDate',
          'write ont_intake_intake-123',
          'write ont_intake_sibling',
        ]);
      });

      test('keeps its window pending for the next operation', () async {
        final elsewhere = mealDate.add(const Duration(hours: 3));
        final other = edit(testIntake, id: 'other', dateTime: elsewhere);
        diary.diaries['a'] = [testIntake, other];
        healthRepo.failingWrites['ont_intake_intake-123'] = 3;

        expect(await usecase.exportIntake(testIntake), isFalse);
        expect(config.pending, {mealDate});

        healthRepo.ops.clear();
        expect(await usecase.exportIntake(other), isTrue);

        expect(healthRepo.ops, [
          'delete window $elsewhere',
          'write ont_intake_other',
          'delete window $mealDate',
          'write ont_intake_intake-123',
        ]);
        expect(config.pending, isEmpty);
      });

      test('is replayed on app start', () async {
        diary.diaries['a'] = [testIntake];
        config.pending = {mealDate};

        expect(await usecase.replayPendingWindows(), isTrue);

        expect(healthRepo.ops, [
          'delete window $mealDate',
          'write ont_intake_intake-123',
        ]);
        expect(config.pending, isEmpty);
      });

      test('a failed read keeps the windows pending', () async {
        diary.switchDuringSnapshot = true;

        expect(await usecase.exportIntake(testIntake), isFalse);

        expect(config.pending, {mealDate});
      });
    });

    group('across profiles', () {
      final sameMinute = mealDate.add(const Duration(seconds: 20));

      test('another exporting profile is rewritten, not erased', () async {
        diary.optIn['b'] = true;
        diary.diaries['b'] = [edit(testIntake, id: 'b1', dateTime: sameMinute)];

        await usecase.deleteIntake(testIntake);

        expect(healthRepo.ops, [
          'delete window $mealDate',
          'write ont_intake_b1',
        ]);
      });

      test('a profile that never opted in is not exported', () async {
        diary.diaries['c'] = [edit(testIntake, id: 'c1', dateTime: sameMinute)];

        await usecase.deleteIntake(testIntake);

        expect(healthRepo.ops, ['delete window $mealDate']);
      });

      test('a profile that opted out again leaves the window alone', () async {
        diary.optIn['b'] = false;
        diary.diaries['b'] = [edit(testIntake, id: 'b1', dateTime: sameMinute)];

        expect(await usecase.deleteIntake(testIntake), isFalse);

        expect(healthRepo.ops, isEmpty);
      });

      // #1393 review: dropping the window lost the recovery work for good.
      test('a blocked window stays pending until consent allows it', () async {
        diary.optIn['b'] = false;
        diary.diaries['b'] = [edit(testIntake, id: 'b1', dateTime: sameMinute)];
        diary.diaries['a'] = [testIntake];
        config.pending = {mealDate};

        expect(await usecase.replayPendingWindows(), isFalse);
        expect(healthRepo.ops, isEmpty);
        expect(config.pending, {mealDate});

        diary.optIn['b'] = true;
        expect(await usecase.replayPendingWindows(), isTrue);

        expect(healthRepo.ops.first, 'delete window $mealDate');
        expect(
          healthRepo.ops.skip(1),
          unorderedEquals([
            'write ont_intake_intake-123',
            'write ont_intake_b1',
          ]),
        );
        expect(config.pending, isEmpty);
      });

      test('a blocked window is rebuilt once its entries are gone', () async {
        diary.optIn['b'] = false;
        diary.diaries['b'] = [edit(testIntake, id: 'b1', dateTime: sameMinute)];
        config.pending = {mealDate};
        await usecase.replayPendingWindows();

        diary.diaries['b'] = [];
        expect(await usecase.replayPendingWindows(), isTrue);

        expect(healthRepo.ops, ['delete window $mealDate']);
        expect(config.pending, isEmpty);
      });

      test('a profile switch while reading deletes nothing', () async {
        diary.diaries['a'] = [testIntake];
        diary.switchDuringSnapshot = true;

        expect(await usecase.exportIntake(testIntake), isFalse);

        expect(healthRepo.ops, isEmpty);
      });
    });
  });

  // #1393 review: a wipe or a profile deletion takes the ids and times that
  // address the exported records with it.
  group('forgetProfile', () {
    final first = edit(testIntake, id: 'first');
    final second = edit(
      testIntake,
      id: 'second',
      dateTime: mealDate.add(const Duration(hours: 3)),
    );

    test('on Health Connect deletes each record by id', () async {
      diary.diaries['a'] = [first, second];

      await usecase.forgetProfile('a');
      await usecase.replayPendingWindows(); // waits for the queue

      expect(healthRepo.ops, [
        'delete ont_intake_first',
        'delete ont_intake_second',
      ]);
    });

    test('an opted-out profile still has its records removed', () async {
      diary.optIn['a'] = false;
      diary.diaries['a'] = [first];

      await usecase.forgetProfile('a');
      await usecase.replayPendingWindows();

      expect(healthRepo.ops, ['delete ont_intake_first']);
    });

    test('a profile that never opted in touches nothing', () async {
      diary.optIn.remove('a');
      diary.diaries['a'] = [first];

      await usecase.forgetProfile('a');
      await usecase.replayPendingWindows();

      expect(healthRepo.ops, isEmpty);
    });

    test('on HealthKit clears the windows, keeping other profiles', () async {
      healthRepo.identity = false;
      final neighbour = edit(
        testIntake,
        id: 'b1',
        dateTime: mealDate.add(const Duration(seconds: 30)),
      );
      // Still on disk when the queue gets to it: the wipe has not run yet.
      diary.diaries['a'] = [first, second];
      diary.optIn['b'] = true;
      diary.diaries['b'] = [neighbour];

      await usecase.forgetProfile('a');
      await usecase.replayPendingWindows();

      expect(healthRepo.ops, [
        'delete window $mealDate',
        'write ont_intake_b1',
        'delete window ${second.dateTime}',
      ]);
    });

    // #1393 review: the ids lived only in the queued closure, so a failed
    // delete or a process exit left the records with nothing to find them.
    test('stores the record ids before the wipe can discard them', () async {
      diary.diaries['a'] = [first, second];
      // Something else is still in flight, so the deletions wait.
      healthRepo.writeGate = Completer<void>();
      final held = usecase.exportIntake(testIntake);

      await usecase.forgetProfile('a');

      expect(config.pendingDeletes, {
        'ont_intake_first',
        'ont_intake_second',
      });
      healthRepo.writeGate!.complete();
      await held;
      await usecase.replayPendingWindows();
      expect(config.pendingDeletes, isEmpty);
    });

    test('a record whose delete fails stays pending until it goes', () async {
      diary.diaries['a'] = [first];
      healthRepo.deleteResult = false;

      await usecase.forgetProfile('a');
      // The wipe clears the diary straight after.
      diary.diaries['a'] = [];
      await usecase.replayPendingWindows();
      expect(config.pendingDeletes, {'ont_intake_first'});

      healthRepo.deleteResult = true;
      healthRepo.ops.clear();
      await usecase.exportIntake(testIntake);

      expect(healthRepo.ops, [
        'delete ont_intake_first',
        'write ont_intake_intake-123',
      ]);
      expect(config.pendingDeletes, isEmpty);
    });

    test('on HealthKit stores the windows before the wipe', () async {
      healthRepo.identity = false;
      diary.diaries['a'] = [first, second];
      healthRepo.writeGate = Completer<void>();
      final held = usecase.exportIntake(testIntake);

      await usecase.forgetProfile('a');

      expect(config.pending, containsAll([mealDate, second.dateTime]));
      healthRepo.writeGate!.complete();
      await held;
    });

    test('a failed read does not throw', () async {
      diary.failReadProfile = true;

      await usecase.forgetProfile('a');

      expect(healthRepo.ops, isEmpty);
    });
  });

  // #1393 review: a HealthKit plugin that failed to start fell back to a
  // service claiming Health Connect's record ids, so iOS edits and deletes
  // kept nothing to recover once the plugin worked again.
  group('with the no-op fallback service', () {
    test('standing in for HealthKit, failures stay pending', () async {
      final fallback = ExportMealIntakeUsecase(
        HealthExportRepository(
          const NoopHealthService(hasRecordIdentity: false),
        ),
        diary,
        config,
        retryDelay: Duration.zero,
      );
      diary.diaries['a'] = [];

      expect(await fallback.deleteIntake(testIntake), isFalse);

      expect(config.pending, {mealDate});
    });

    test('by default it keeps Health Connect semantics', () {
      expect(const NoopHealthService().hasRecordIdentity, isTrue);
    });
  });

  group('Intake usecases live export triggers', () {
    late _FakeIntakeRepository intakeRepo;

    setUp(() => intakeRepo = _FakeIntakeRepository());

    test('AddIntakeUsecase persists and triggers live export', () async {
      final addUsecase = AddIntakeUsecase(intakeRepo, usecase);

      await addUsecase.addIntake(testIntake);
      await Future<void>.delayed(Duration.zero);

      expect(intakeRepo.addedIntakes, contains(testIntake));
      expect(healthRepo.ops, ['write ont_intake_intake-123']);
    });

    test('UpdateIntakeUsecase hands over the entry as it was', () async {
      healthRepo.identity = false;
      final moved = mealDate.add(const Duration(hours: 2));
      final after = edit(testIntake, dateTime: moved);
      intakeRepo.storedIntakes = [testIntake];
      intakeRepo.updatedIntakeResult = after;
      diary.diaries['a'] = [after];
      final updateUsecase = UpdateIntakeUsecase(intakeRepo, usecase);

      expect(await updateUsecase.updateIntake('intake-123', {}), after);
      await Future<void>.delayed(Duration.zero);

      // The old window is only known from the entry read before the edit.
      expect(healthRepo.ops, [
        'delete window $mealDate',
        'delete window $moved',
        'write ont_intake_intake-123',
      ]);
    });

    test('DeleteIntakeUsecase deletes and triggers a health delete', () async {
      final deleteUsecase = DeleteIntakeUsecase(intakeRepo, usecase);

      await deleteUsecase.deleteIntake(testIntake);
      await Future<void>.delayed(Duration.zero);

      expect(intakeRepo.deletedIntakes, contains(testIntake));
      expect(healthRepo.ops, ['delete ont_intake_intake-123']);
    });
  });
}
