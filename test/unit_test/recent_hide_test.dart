import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/hidden_recent_data_source.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/hide_recent_meal_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

/// #1198: removing a food from the add-meal Recently list hides that row
/// only — it never deletes a diary entry or a saved food — and logging the
/// food again brings it back.

MealDBO _meal(String? code, String? name, {MealSourceDBO? source}) => MealDBO(
  code: code,
  name: name,
  brands: null,
  thumbnailImageUrl: null,
  mainImageUrl: null,
  url: null,
  mealQuantity: '100',
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: 'g',
  servingSize: null,
  nutriments: MealNutrimentsDBO(
    energyKcal100: 100,
    carbohydrates100: null,
    fat100: null,
    proteins100: null,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  source: source ?? MealSourceDBO.custom,
);

IntakeDBO _intake(String id, MealDBO meal, DateTime at) => IntakeDBO(
  id: id,
  unit: 'g',
  amount: 100,
  type: IntakeTypeDBO.lunch,
  meal: meal,
  dateTime: at,
);

/// A provider whose per-profile boxes follow [activeProfileId], the way the
/// real one swaps its whole box-set on a profile switch.
class _TwoProfileProvider extends FakeHiveDBProvider {
  final Map<String, Box<IntakeDBO>> intakes;
  final Map<String, Box<DateTime>> hidden;

  _TwoProfileProvider(this.intakes, this.hidden) : super(activeProfileId: 'a');

  @override
  Box<IntakeDBO> get intakeBox => intakes[activeProfileId]!;

  @override
  Box<DateTime> get hiddenRecentBox => hidden[activeProfileId]!;
}

class _Sut {
  final GetIntakeUsecase getIntake;
  final HideRecentMealUsecase hide;

  _Sut(FakeHiveDBProvider provider)
    : getIntake = GetIntakeUsecase(
        IntakeRepository(IntakeDataSource(provider)),
        RecipeRepository(RecipeDataSource(provider)),
        HiddenRecentDataSource(provider),
      ),
      hide = HideRecentMealUsecase(
        IntakeRepository(IntakeDataSource(provider)),
        HiddenRecentDataSource(provider),
      );

  Future<List<String?>> recentNames() async =>
      (await getIntake.getRecentIntake()).map((i) => i.meal.name).toList();

  Future<List<String?>> recentCodes() async =>
      (await getIntake.getRecentIntake()).map((i) => i.meal.code).toList();

  Future<MealEntity> rowNamed(String name) async =>
      (await getIntake.getRecentIntake())
          .firstWhere((i) => i.meal.name == name)
          .meal;
}

void main() {
  late Box<IntakeDBO> intakeBox;
  late Box<DateTime> hiddenBox;
  late _Sut sut;
  var seq = 0;

  Future<Box<T>> openBox<T>(String name) => Hive.openBox<T>(
    '${name}_${DateTime.now().microsecondsSinceEpoch}_'
    '${seq++}',
  );

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Hive.init('.');
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    intakeBox = await openBox<IntakeDBO>('hide_recent_intake');
    hiddenBox = await openBox<DateTime>('hide_recent_hidden');
    sut = _Sut(
      FakeHiveDBProvider(intakeBox: intakeBox, hiddenRecentBox: hiddenBox),
    );
  });

  tearDown(() async {
    await intakeBox.deleteFromDisk();
    await hiddenBox.deleteFromDisk();
  });

  test(
    'an empty Recently list stays empty, and hiding into it is a no-op',
    () async {
      expect(await sut.recentNames(), isEmpty);

      await sut.hide.hide(MealEntity.fromMealDBO(_meal('x', 'Ghost')));

      expect(await sut.recentNames(), isEmpty);
      expect(hiddenBox.isEmpty, isTrue);
    },
  );

  test(
    'hiding a row removes it from Recently and keeps every diary entry',
    () async {
      await intakeBox.addAll([
        _intake('1', _meal('a', 'Apple'), DateTime(2026, 11, 1)),
        _intake('2', _meal('a', 'Apple'), DateTime(2026, 11, 2)),
        _intake('3', _meal('b', 'Bread'), DateTime(2026, 11, 3)),
      ]);

      await sut.hide.hide(await sut.rowNamed('Apple'));

      expect(await sut.recentNames(), ['Bread']);
      expect(intakeBox.values.map((i) => i.id), ['1', '2', '3']);
    },
  );

  test('hiding the last row leaves an empty list', () async {
    await intakeBox.add(
      _intake('1', _meal('a', 'Apple'), DateTime(2026, 11, 1)),
    );

    await sut.hide.hide(await sut.rowNamed('Apple'));

    expect(await sut.recentNames(), isEmpty);
    expect(intakeBox.length, 1);
  });

  test('a hidden food comes back once it is logged again', () async {
    await intakeBox.add(
      _intake('1', _meal('a', 'Apple'), DateTime(2026, 11, 5)),
    );
    await sut.hide.hide(await sut.rowNamed('Apple'));
    expect(await sut.recentNames(), isEmpty);

    // Logged again onto an earlier day than the hidden entry: the new entry
    // is what brings the row back, not its date.
    await intakeBox.add(
      _intake('2', _meal('a', 'Apple'), DateTime(2026, 11, 1)),
    );

    expect(await sut.recentNames(), ['Apple']);
  });

  test('Quick Add entries sort by when they were logged, not on top', () async {
    await intakeBox.addAll([
      _intake('1', _meal('q1', 'Quick'), DateTime(2026, 11, 1)),
      _intake(
        '2',
        _meal('o1', 'Oats', source: MealSourceDBO.off),
        DateTime(2026, 11, 3),
      ),
      _intake('3', _meal('q2', 'Quick 2'), DateTime(2026, 11, 2)),
    ]);

    expect(await sut.recentNames(), ['Oats', 'Quick 2', 'Quick']);
  });

  test('two Quick Add entries with the same name hide one at a time', () async {
    await intakeBox.addAll([
      _intake('1', _meal('q1', 'Snack'), DateTime(2026, 11, 1)),
      _intake('2', _meal('q2', 'Snack'), DateTime(2026, 11, 2)),
    ]);
    final rows = await sut.getIntake.getRecentIntake();
    expect(rows.map((r) => r.meal.code), ['q2', 'q1']);

    await sut.hide.hide(rows.first.meal);

    expect(await sut.recentCodes(), ['q1']);
  });

  test('a food without a code is matched by its name', () async {
    await intakeBox.addAll([
      _intake('1', _meal(null, 'Legacy'), DateTime(2026, 11, 1)),
      _intake('2', _meal(null, 'Legacy'), DateTime(2026, 11, 2)),
      _intake('3', _meal(null, 'Other'), DateTime(2026, 11, 3)),
    ]);

    await sut.hide.hide(await sut.rowNamed('Legacy'));

    expect(await sut.recentNames(), ['Other']);
  });

  test('search still finds a hidden Quick Add entry', () async {
    await intakeBox.add(
      _intake('1', _meal('q1', 'Snack'), DateTime(2026, 11, 1)),
    );

    await sut.hide.hide(await sut.rowNamed('Snack'));

    expect(await sut.recentNames(), isEmpty);
    final history = await sut.getIntake.getRecentIntakeIncludingHidden();
    expect(history.map((i) => i.meal.name), ['Snack']);
  });

  test('an entry id too long for a Hive key can still be hidden', () async {
    final longId = 'x' * 400;
    await intakeBox.add(
      _intake(longId, _meal('a', 'Apple'), DateTime(2026, 11, 1)),
    );

    await sut.hide.hide(await sut.rowNamed('Apple'));

    expect(await sut.recentNames(), isEmpty);
  });

  test('each profile keeps its own hidden rows', () async {
    final intakeB = await openBox<IntakeDBO>('hide_recent_intake_b');
    final hiddenB = await openBox<DateTime>('hide_recent_hidden_b');
    addTearDown(() async {
      await intakeB.deleteFromDisk();
      await hiddenB.deleteFromDisk();
    });
    final provider = _TwoProfileProvider(
      {'a': intakeBox, 'b': intakeB},
      {'a': hiddenBox, 'b': hiddenB},
    );
    final twoProfiles = _Sut(provider);
    // The same entry in both profiles, as a copy to another profile makes.
    await intakeBox.add(
      _intake('1', _meal('a', 'Apple'), DateTime(2026, 11, 1)),
    );
    await intakeB.add(_intake('1', _meal('a', 'Apple'), DateTime(2026, 11, 1)));

    await twoProfiles.hide.hide(await twoProfiles.rowNamed('Apple'));
    expect(await twoProfiles.recentNames(), isEmpty);

    provider.activeProfileId = 'b';
    expect(await twoProfiles.recentNames(), ['Apple']);

    provider.activeProfileId = 'a';
    expect(await twoProfiles.recentNames(), isEmpty);
  });
}
