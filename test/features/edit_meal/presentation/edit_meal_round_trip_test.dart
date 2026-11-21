import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/favourite_meal_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/edit_meal/presentation/bloc/edit_meal_bloc.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../helpers/test_l10n.dart';

/// Opening a custom meal in the editor and saving it must not change what
/// the user did not change (#1466).
///
/// The form shows some values rounded (energy to one decimal, imperial
/// sizes to two), and the save used to read them back from the rounded
/// text. A field left as it was seeded now saves the stored value at full
/// precision. A field cleared to blank is "not set" for every nutrient, and
/// changing only the base quantity still rescales, with a note saying so.
void main() {
  final getIt = GetIt.instance;
  late _RecordingCustomMealDataSource dataSource;
  late _FakeConfigRepository configRepository;

  setUp(() {
    dataSource = _RecordingCustomMealDataSource();
    configRepository = _FakeConfigRepository();
    getIt.registerFactory<EditMealBloc>(
      () => EditMealBloc(
        _FakeGetConfigUsecase(),
        dataSource,
        configRepository,
        _FakeFavouriteMealRepository(),
        _FakeIntakeRepository(),
      ),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  /// 7 kcal per 30 g, stored per 100 g: the per-100 values have more
  /// decimals than the form shows (the issue's Case A).
  const thirds = MealNutrimentsEntity(
    energyKcal100: 7 / 30 * 100,
    carbohydrates100: 1 / 30 * 100,
    fat100: 0.1 / 30 * 100,
    proteins100: 0.5 / 30 * 100,
    sugars100: 5 / 30 * 100,
    saturatedFat100: null,
    fiber100: 0.1,
    sodium100: 123.45678,
  );

  MealEntity customMeal({
    MealNutrimentsEntity nutriments = thirds,
    String? mealQuantity = '30',
    double? servingQuantity = 30,
    String unit = 'g',
  }) => MealEntity(
    code: 'uuid-oats',
    name: 'Oats',
    url: null,
    mealQuantity: mealQuantity,
    mealUnit: unit,
    servingQuantity: servingQuantity,
    servingUnit: unit,
    servingSize: '',
    nutriments: nutriments,
    source: MealSourceEntity.custom,
  );

  Future<EnergyUnitProvider> pumpEditor(
    WidgetTester tester,
    MealEntity meal, {
    CustomMealFormMode mode = CustomMealFormMode.advanced,
    bool imperial = false,
    bool kJ = false,
  }) async {
    configRepository.mode = mode;
    final energyUnit = EnergyUnitProvider(usesKilojoules: kJ);
    // Tall enough that every field of the Advanced form is built.
    tester.view.physicalSize = const Size(1080, 9000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<EnergyUnitProvider>.value(
        value: energyUnit,
        child: MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          onGenerateInitialRoutes: (_) => [
            MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('custom meals')),
            ),
            MaterialPageRoute<void>(
              settings: RouteSettings(
                arguments: EditMealScreenArguments(
                  DateTime(2026, 11, 9),
                  meal,
                  IntakeTypeEntity.breakfast,
                  imperial,
                  editOnly: true,
                ),
              ),
              builder: (_) => const EditMealScreen(),
            ),
          ],
          onGenerateRoute: (_) => null,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return energyUnit;
  }

  Future<MealDBO> save(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, l10nEn.buttonSaveLabel));
    await tester.pumpAndSettle();
    expect(dataSource.saves, hasLength(1), reason: 'the save went through');
    return dataSource.saves.single;
  }

  MealNutrimentsEntity nutrimentsOf(MealDBO saved) =>
      MealEntity.fromMealDBO(saved).nutriments;

  Finder field(String label) => find.widgetWithText(TextFormField, label);
  Finder energyField({bool kJ = false}) => field(
    '${l10nEn.mealEnergyLabel} (${kJ ? l10nEn.kjLabel : l10nEn.kcalLabel})',
  );
  Finder baseField() =>
      field('${l10nEn.baseQuantityLabel} (${l10nEn.gramUnit})');

  group('saving without changes keeps the meal as it was', () {
    testWidgets('metric, kcal, Advanced (Case A)', (tester) async {
      await pumpEditor(tester, customMeal());
      // What the field shows is rounded; what is saved must not be.
      expect(find.text('23.3'), findsOneWidget);

      final saved = await save(tester);

      expect(nutrimentsOf(saved), thirds);
      expect(saved.nutriments.energyKcal100, 7 / 30 * 100);
      expect(saved.mealQuantity, '30');
      expect(saved.servingQuantity, 30);
      expect(saved.mealUnit, 'g');
    });

    testWidgets('metric, kJ, Advanced', (tester) async {
      await pumpEditor(tester, customMeal(), kJ: true);
      expect(find.text('97.6'), findsOneWidget);

      final saved = await save(tester);

      expect(nutrimentsOf(saved), thirds);
    });

    testWidgets('imperial, Advanced (Case B)', (tester) async {
      await pumpEditor(
        tester,
        customMeal(mealQuantity: '100', servingQuantity: 100),
        imperial: true,
      );
      expect(find.text('3.53'), findsNWidgets(2));

      final saved = await save(tester);

      expect(saved.mealQuantity, '100');
      expect(saved.servingQuantity, 100);
      expect(nutrimentsOf(saved), thirds);
    });

    testWidgets('imperial and kJ together, Advanced', (tester) async {
      await pumpEditor(tester, customMeal(), imperial: true, kJ: true);

      final saved = await save(tester);

      expect(saved.mealQuantity, '30');
      expect(saved.servingQuantity, 30);
      expect(nutrimentsOf(saved), thirds);
    });

    testWidgets('kcal, Simple', (tester) async {
      await pumpEditor(tester, customMeal(), mode: CustomMealFormMode.simple);

      final saved = await save(tester);

      expect(nutrimentsOf(saved), thirds);
    });

    testWidgets('kJ, Simple', (tester) async {
      await pumpEditor(
        tester,
        customMeal(),
        mode: CustomMealFormMode.simple,
        kJ: true,
      );

      final saved = await save(tester);

      expect(nutrimentsOf(saved), thirds);
    });

    testWidgets(
      'switching kcal to kJ while editing keeps an untouched energy',
      (tester) async {
        final energyUnit = await pumpEditor(tester, customMeal());

        energyUnit.updateUsesKilojoules(true);
        await tester.pumpAndSettle();
        expect(find.text('97.6'), findsOneWidget);

        final saved = await save(tester);

        expect(saved.nutriments.energyKcal100, 7 / 30 * 100);
      },
    );

    testWidgets('a meal with no micronutrients keeps them unset', (
      tester,
    ) async {
      const noMicros = MealNutrimentsEntity(
        energyKcal100: 7 / 30 * 100,
        carbohydrates100: 1 / 30 * 100,
        fat100: 0.1 / 30 * 100,
        proteins100: 0.5 / 30 * 100,
        sugars100: null,
        saturatedFat100: null,
        fiber100: null,
      );
      await pumpEditor(tester, customMeal(nutriments: noMicros));

      final saved = await save(tester);

      expect(nutrimentsOf(saved), noMicros);
    });

    testWidgets('a meal with no size keeps it unset in imperial', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        customMeal(mealQuantity: null, servingQuantity: null),
        imperial: true,
      );

      final saved = await save(tester);

      expect(saved.mealQuantity, isNull);
      expect(saved.servingQuantity, isNull);
    });

    testWidgets('very small values', (tester) async {
      const tiny = MealNutrimentsEntity(
        energyKcal100: 0.004,
        carbohydrates100: null,
        fat100: null,
        proteins100: null,
        sugars100: 0.0001,
        saturatedFat100: null,
        fiber100: 1e-7,
        sodium100: 0.00042,
      );
      await pumpEditor(tester, customMeal(nutriments: tiny));
      expect(find.text('0.0'), findsOneWidget);

      final saved = await save(tester);

      expect(nutrimentsOf(saved), tiny);
    });

    testWidgets('very large values, imperial', (tester) async {
      const large = MealNutrimentsEntity(
        energyKcal100: 899.96,
        carbohydrates100: 0,
        fat100: 99.99,
        proteins100: 0,
        sugars100: null,
        saturatedFat100: 65.4321,
        fiber100: null,
        sodium100: 123456.789,
        potassium100: 98765.4321,
      );
      await pumpEditor(
        tester,
        customMeal(
          nutriments: large,
          mealQuantity: '123456.789',
          servingQuantity: 98765.4321,
        ),
        imperial: true,
      );
      expect(find.text('900.0'), findsOneWidget);

      final saved = await save(tester);

      expect(nutrimentsOf(saved), large);
      expect(saved.mealQuantity, '123456.789');
      expect(saved.servingQuantity, 98765.4321);
    });
    testWidgets('a size stored with a decimal comma keeps its value', (
      tester,
    ) async {
      await pumpEditor(tester, customMeal(mealQuantity: '137,5'));

      final saved = await save(tester);

      // Same number; the comma becomes a period as the form loads it.
      expect(saved.mealQuantity, '137.5');
      expect(nutrimentsOf(saved), thirds);
    });

    testWidgets('switching to Total reads the untouched values as totals', (
      tester,
    ) async {
      await pumpEditor(tester, customMeal());

      await tester.tap(find.text(l10nEn.mealNutrientsTotalLabel));
      await tester.pumpAndSettle();
      final saved = await save(tester);

      // The shown per-100 numbers now mean "for the whole 30 g", as before,
      // but from the stored value rather than the rounded text.
      expect(saved.nutriments.energyKcal100, (7 / 30 * 100) / 30 * 100);
      expect(saved.nutriments.sugars100, (5 / 30 * 100) / 30 * 100);
    });
  });

  group('editing one field changes only that field', () {
    testWidgets('energy', (tester) async {
      await pumpEditor(tester, customMeal());

      await tester.enterText(energyField(), '23.5');
      final saved = await save(tester);

      expect(nutrimentsOf(saved), thirds.replace(energyKcal100: 23.5));
      expect(saved.mealQuantity, '30');
    });

    testWidgets('a micronutrient, typed with a decimal comma', (tester) async {
      await pumpEditor(tester, customMeal());

      await tester.enterText(field(l10nEn.sugarLabel), '12,5');
      final saved = await save(tester);

      expect(nutrimentsOf(saved), thirds.replace(sugars100: 12.5));
    });

    testWidgets('energy typed with a decimal comma', (tester) async {
      await pumpEditor(tester, customMeal());

      await tester.enterText(energyField(), '23,25');
      final saved = await save(tester);

      expect(saved.nutriments.energyKcal100, 23.25);
      expect(saved.nutriments.carbohydrates100, 1 / 30 * 100);
    });

    testWidgets('the meal size in imperial', (tester) async {
      await pumpEditor(
        tester,
        customMeal(mealQuantity: '100', servingQuantity: 100),
        imperial: true,
      );

      await tester.enterText(
        field('${l10nEn.mealSizeLabel} (${l10nEn.ozUnit})'),
        '2',
      );
      final saved = await save(tester);

      expect(double.parse(saved.mealQuantity!), closeTo(56.7, 0.01));
      expect(saved.servingQuantity, 100);
      expect(nutrimentsOf(saved), thirds);
    });

    testWidgets('the unit in imperial reconverts the shown size', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        customMeal(mealQuantity: '100', servingQuantity: 100),
        imperial: true,
      );

      // The field keeps showing 3.53, now read as fl oz.
      await tester.tap(find.text(l10nEn.flOzUnit));
      await tester.pumpAndSettle();
      final saved = await save(tester);

      expect(saved.mealUnit, 'ml');
      expect(double.parse(saved.mealQuantity!), closeTo(104.4, 0.1));
    });
  });

  group('changing only the base quantity (Case C)', () {
    testWidgets('shows that the values below are read per that amount', (
      tester,
    ) async {
      await pumpEditor(tester, customMeal());

      expect(find.text(l10nEn.baseQuantityRescaleHelper), findsOneWidget);
    });

    testWidgets('rescales the untouched values from their stored precision', (
      tester,
    ) async {
      await pumpEditor(tester, customMeal());

      await tester.enterText(baseField(), '50');
      final saved = await save(tester);

      final n = nutrimentsOf(saved);
      expect(n.energyKcal100, (7 / 30 * 100) * 2);
      expect(n.carbohydrates100, (1 / 30 * 100) * 2);
      expect(n.sugars100, (5 / 30 * 100) * 2);
      expect(n.fiber100, 0.2);
      expect(n.saturatedFat100, isNull);
      expect(saved.mealQuantity, '30');
    });

    testWidgets('a base quantity of 100 changes nothing', (tester) async {
      await pumpEditor(tester, customMeal());

      await tester.enterText(baseField(), '100');
      final saved = await save(tester);

      expect(nutrimentsOf(saved), thirds);
    });
  });

  group('a field cleared to blank (Case D)', () {
    testWidgets('a macronutrient and a micronutrient both become unset', (
      tester,
    ) async {
      await pumpEditor(tester, customMeal());

      await tester.enterText(field(l10nEn.mealFatLabel), '');
      await tester.enterText(field(l10nEn.sugarLabel), '');
      final saved = await save(tester);

      expect(
        nutrimentsOf(saved),
        thirds.replace(fat100: null, sugars100: null),
      );
    });

    testWidgets('energy and sodium both become unset', (tester) async {
      await pumpEditor(tester, customMeal());

      await tester.enterText(energyField(), '');
      await tester.enterText(field(l10nEn.sodiumLabel), '');
      final saved = await save(tester);

      final n = nutrimentsOf(saved);
      expect(n.energyKcal100, isNull);
      expect(n.sodium100, isNull);
      expect(n.carbohydrates100, 1 / 30 * 100);
      expect(n.sugars100, 5 / 30 * 100);
    });

    testWidgets('a cleared field opens blank the next time', (tester) async {
      await pumpEditor(tester, customMeal());
      await tester.enterText(field(l10nEn.sugarLabel), '');
      final saved = await save(tester);
      await tester.pumpWidget(const SizedBox());

      await pumpEditor(tester, MealEntity.fromMealDBO(saved));

      final sugar = tester.widget<TextFormField>(field(l10nEn.sugarLabel));
      expect(sugar.controller!.text, isEmpty);
    });

    testWidgets('Simple mode keeps saving a cleared macro as 0', (
      tester,
    ) async {
      await pumpEditor(tester, customMeal(), mode: CustomMealFormMode.simple);

      await tester.enterText(field(l10nEn.mealFatLabel), '');
      final saved = await save(tester);

      expect(saved.nutriments.fat100, 0);
      expect(saved.nutriments.carbohydrates100, 1 / 30 * 100);
    });
  });

  group('EditMealBloc.createNewMealEntity', () {
    late EditMealBloc bloc;
    setUp(() => bloc = getIt<EditMealBloc>());

    MealEntity build({String? sugarsText, String fatText = '1'}) =>
        bloc.createNewMealEntity(
          customMeal(),
          'Oats',
          '',
          '30',
          '30',
          '',
          'g',
          '23.3',
          '3',
          fatText,
          '1',
          sugarsText: sugarsText,
        );

    test('a blank micronutrient is unset, like a blank macronutrient', () {
      final meal = build(sugarsText: '', fatText: '');
      expect(meal.nutriments.fat100, isNull);
      expect(meal.nutriments.sugars100, isNull);
    });

    test('a micronutrient the form does not pass keeps its stored value', () {
      expect(build().nutriments.sugars100, 5 / 30 * 100);
    });
  });
}

const _keep = Object();

extension on MealNutrimentsEntity {
  /// This entity with the given fields replaced; unlike a `copyWith`, a
  /// field can be replaced with null.
  MealNutrimentsEntity replace({
    Object? energyKcal100 = _keep,
    Object? fat100 = _keep,
    Object? sugars100 = _keep,
  }) => MealNutrimentsEntity(
    energyKcal100: identical(energyKcal100, _keep)
        ? this.energyKcal100
        : energyKcal100 as double?,
    carbohydrates100: carbohydrates100,
    fat100: identical(fat100, _keep) ? this.fat100 : fat100 as double?,
    proteins100: proteins100,
    sugars100: identical(sugars100, _keep)
        ? this.sugars100
        : sugars100 as double?,
    saturatedFat100: saturatedFat100,
    fiber100: fiber100,
    sodium100: sodium100,
    calcium100: calcium100,
    iron100: iron100,
    potassium100: potassium100,
    magnesium100: magnesium100,
    vitaminD100: vitaminD100,
    vitaminB12100: vitaminB12100,
  );
}

class _RecordingCustomMealDataSource implements CustomMealDataSource {
  final saves = <MealDBO>[];

  @override
  List<MealDBO> getAllCustomMeals() => const [];

  @override
  Future<void> saveCustomMeal(MealDBO mealDBO, {MealDBO? previous}) async {
    saves.add(mealDBO);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeIntakeRepository implements IntakeRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetConfigUsecase implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(true, true, false, AppThemeEntity.system);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeConfigRepository implements ConfigRepository {
  CustomMealFormMode mode = CustomMealFormMode.advanced;

  @override
  Future<String?> getCustomMealFormMode() async => mode.name;

  @override
  Future<void> setCustomMealFormMode(String mode) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeFavouriteMealRepository implements FavouriteMealRepository {
  @override
  Future<void> moveFavourite(MealEntity previous, MealEntity updated) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}
