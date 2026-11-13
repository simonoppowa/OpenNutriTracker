import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/favourite_meal_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/edit_meal/presentation/bloc/edit_meal_bloc.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/features/meal_detail/util/meal_quantity_converter.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../helpers/fake_hive_db_provider.dart';
import '../../../helpers/hive_test_setup.dart';
import '../../../helpers/test_l10n.dart';

// Synthetic basis fixture, not evidence about any real product.
MealEntity _food({
  String unit = 'g',
  String? quantity = '60',
  double? servingQuantity,
}) => MealEntity(
  code: 'basis-food',
  name: 'Sixty gram food',
  url: null,
  mealQuantity: quantity,
  mealUnit: unit,
  servingQuantity: servingQuantity ?? double.tryParse(quantity ?? ''),
  servingUnit: unit,
  servingSize: '1 portion ($quantity $unit)',
  nutriments: const MealNutrimentsEntity(
    energyKcal100: 460,
    carbohydrates100: 60,
    fat100: 20,
    proteins100: 10,
    sugars100: 12,
    saturatedFat100: 5,
    fiber100: 8,
    sodium100: 100,
    calcium100: 40,
    iron100: 2,
    potassium100: 300,
    magnesium100: 10,
    vitaminB12100: 0.5,
  ),
  source: MealSourceEntity.custom,
  detailed: true,
);

void main() {
  late Directory directory;
  late Box<MealDBO> box;
  late CustomMealDataSource library;
  late Box<ConfigDBO> configBox;
  late ConfigRepository preferences;
  final editors = <EditMealBloc>[];
  var imperial = false;
  var kilojoules = false;

  setUp(() async {
    imperial = false;
    kilojoules = false;
    directory = await Directory.systemTemp.createTemp('nutrition-basis-');
    Hive.init(directory.path);
    registerHiveAdaptersOnce();
    configBox = await Hive.openBox<ConfigDBO>('config');
    preferences = ConfigRepository(
      ConfigDataSource(FakeHiveDBProvider(configBox: configBox)),
    );
    box = await Hive.openBox<MealDBO>('custom-meals');
    library = CustomMealDataSource(FakeHiveDBProvider(customMealBox: box));
    GetIt.instance.registerFactory<EditMealBloc>(() {
      final bloc = EditMealBloc(
        _Config(imperial),
        library,
        preferences,
        _Favourites(),
        _Intakes(),
      );
      editors.add(bloc);
      return bloc;
    });
  });

  tearDown(() async {
    for (final editor in editors) {
      await editor.close();
    }
    editors.clear();
    await GetIt.instance.reset();
    await configBox.deleteFromDisk();
    await box.deleteFromDisk();
    await directory.delete(recursive: true);
  });

  Future<void> pumpEditor(
    WidgetTester tester,
    MealEntity meal, {
    Size size = const Size(1080, 2400),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => EnergyUnitProvider(usesKilojoules: kilojoules),
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          onGenerateRoute: (_) =>
              MaterialPageRoute<void>(builder: (_) => const Scaffold()),
          onGenerateInitialRoutes: (_) => [
            MaterialPageRoute<void>(builder: (_) => const Scaffold()),
            MaterialPageRoute<void>(
              settings: RouteSettings(
                arguments: EditMealScreenArguments(
                  DateTime(2026, 10, 31),
                  meal,
                  IntakeTypeEntity.breakfast,
                  imperial,
                  editOnly: true,
                ),
              ),
              builder: (_) => const EditMealScreen(),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<Finder> field(WidgetTester tester, String label) async {
    final finder = find.widgetWithText(TextFormField, label);
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    return finder;
  }

  Future<TextFormField> energy(
    WidgetTester tester,
  ) async => tester.widget<TextFormField>(
    await field(
      tester,
      '${l10nEn.mealEnergyLabel} (${kilojoules ? l10nEn.kjLabel : l10nEn.kcalLabel})',
    ),
  );

  Future<void> toggleTotal(WidgetTester tester) async {
    final toggle = find.byType(SegmentedButton<bool>);
    await tester.scrollUntilVisible(
      toggle,
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.runAsync(() async {
      await tester.tap(
        find.textContaining(l10nEn.mealNutrientsTotalLabel).first,
      );
      await configBox.flush();
    });
    await tester.pumpAndSettle();
  }

  Future<MealEntity> saveAndReopen(
    WidgetTester tester, {
    bool acceptWarning = false,
  }) async {
    await tester.runAsync(() async {
      await tester.tap(
        find.widgetWithText(FilledButton, l10nEn.buttonSaveLabel),
      );
      await box.flush();
    });
    await tester.pumpAndSettle();
    final saveAnyway = find.text(l10nEn.inconsistentNutritionWarningSaveAnyway);
    if (acceptWarning && saveAnyway.evaluate().isNotEmpty) {
      await tester.runAsync(() async {
        await tester.tap(saveAnyway);
        await box.flush();
      });
      await tester.pumpAndSettle();
    }
    expect(find.byType(EditMealScreen), findsNothing);
    await tester.runAsync(() async {
      await box.close();
      box = await Hive.openBox<MealDBO>('custom-meals');
    });
    library = CustomMealDataSource(FakeHiveDBProvider(customMealBox: box));
    return MealEntity.fromMealDBO(library.getAllCustomMeals().single);
  }

  Future<void> simple(WidgetTester tester) async {
    final toggle = find.byType(SegmentedButton<CustomMealFormMode>);
    await tester.scrollUntilVisible(
      toggle,
      -300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.runAsync(() async {
      await tester.tap(find.text(l10nEn.customMealFormSimple).first);
      await configBox.flush();
    });
    await tester.pumpAndSettle();
  }

  Future<void> advanced(WidgetTester tester) async {
    final toggle = find.byType(SegmentedButton<CustomMealFormMode>);
    await tester.scrollUntilVisible(
      toggle,
      -300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.runAsync(() async {
      await tester.tap(find.text(l10nEn.customMealFormAdvanced).first);
      await configBox.flush();
    });
    await tester.pumpAndSettle();
  }

  Future<void> per100(WidgetTester tester, String unit) async {
    await field(tester, '${l10nEn.baseQuantityLabel} ($unit)');
    await tester.runAsync(() async {
      await tester.tap(find.text('Per 100 $unit').first);
      await configBox.flush();
    });
    await tester.pumpAndSettle();
  }

  void expectDensity(MealEntity meal) {
    final n = meal.nutriments;
    expect(n.energyKcal100, closeTo(460, 0.15));
    expect(n.carbohydrates100, closeTo(60, 0.0001));
    expect(n.fat100, closeTo(20, 0.0001));
    expect(n.proteins100, closeTo(10, 0.0001));
    expect(n.fiber100, closeTo(8, 0.0001));
    expect(n.sugars100, closeTo(12, 0.0001));
    expect(n.saturatedFat100, closeTo(5, 0.0001));
    expect(n.sodium100, closeTo(100, 0.0001));
    expect(n.calcium100, closeTo(40, 0.0001));
    expect(n.iron100, closeTo(2, 0.0001));
    expect(n.potassium100, closeTo(300, 0.0001));
    expect(n.magnesium100, closeTo(10, 0.0001));
    expect(n.vitaminD100, isNull);
    expect(n.vitaminB12100, closeTo(0.5, 0.0001));
  }

  Future<void> reopenPreferences(WidgetTester tester) async {
    await tester.runAsync(() async {
      await configBox.close();
      configBox = await Hive.openBox<ConfigDBO>('config');
    });
    preferences = ConfigRepository(
      ConfigDataSource(FakeHiveDBProvider(configBox: configBox)),
    );
  }

  testWidgets('remembers explicit package-total selection on reopen', (
    tester,
  ) async {
    final meal = _food(quantity: '400', servingQuantity: 40);
    await pumpEditor(tester, meal);
    await toggleTotal(tester);
    expect(double.parse((await energy(tester)).controller!.text), 1840);
    final reopened = await saveAndReopen(tester);
    expectDensity(reopened);
    expect(double.parse(reopened.mealQuantity!), 400);
    expect(reopened.servingQuantity, 40);
    await reopenPreferences(tester);
    expect(await preferences.getCustomMealNutrientsTotal(), isTrue);
    await pumpEditor(tester, reopened);
    expect(double.parse((await energy(tester)).controller!.text), 1840);
    for (final entry in {
      l10nEn.mealCarbsLabel: 240,
      l10nEn.mealFatLabel: 80,
      l10nEn.mealProteinLabel: 40,
    }.entries) {
      final input = tester.widget<TextFormField>(
        await field(tester, entry.key),
      );
      expect(double.parse(input.controller!.text), entry.value);
    }
    // Unchanged total save normalizes every populated nutrient once.
    expectDensity(await saveAndReopen(tester));
    await pumpEditor(tester, reopened);
    await per100(tester, 'g');
    await reopenPreferences(tester);
    expect(await preferences.getCustomMealNutrientsTotal(), isFalse);
    await pumpEditor(tester, reopened);
    expect(double.parse((await energy(tester)).controller!.text), 460);
    expectDensity(await saveAndReopen(tester));
  });

  testWidgets('legacy absent preference keeps Per100 default', (tester) async {
    await tester.runAsync(() async {
      final legacy = ConfigDBO.empty().toJson()
        ..remove('customMealNutrientsTotal');
      await configBox.put('ConfigKey', ConfigDBO.fromJson(legacy));
    });
    await reopenPreferences(tester);
    expect(await preferences.getCustomMealNutrientsTotal(), isFalse);
    await pumpEditor(tester, _food(quantity: '400', servingQuantity: 40));
    expect(double.parse((await energy(tester)).controller!.text), 460);
  });

  for (final quantity in [null, '', '0', '-10', 'invalid', 'NaN', 'Infinity']) {
    testWidgets('remembered total safely falls back for package $quantity', (
      tester,
    ) async {
      await tester.runAsync(
        () => preferences.setCustomMealNutrientsTotal(true),
      );
      await pumpEditor(tester, _food(quantity: quantity, servingQuantity: 40));
      expect(
        tester
            .widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>))
            .selected,
        {false},
      );
      expect(double.parse((await energy(tester)).controller!.text), 460);
      await reopenPreferences(tester);
      expect(await preferences.getCustomMealNutrientsTotal(), isTrue);
      await pumpEditor(tester, _food(quantity: '400', servingQuantity: 40));
      expect(double.parse((await energy(tester)).controller!.text), 1840);
    });
  }

  testWidgets('Simple hydration does not overwrite Advanced total preference', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await preferences.setCustomMealNutrientsTotal(true);
      await preferences.setCustomMealFormMode('simple');
    });
    await pumpEditor(tester, MealEntity.empty());
    expect(
      tester
          .widget<SegmentedButton<CustomMealFormMode>>(
            find.byType(SegmentedButton<CustomMealFormMode>),
          )
          .selected,
      {CustomMealFormMode.simple},
    );
    await reopenPreferences(tester);
    expect(await preferences.getCustomMealNutrientsTotal(), isTrue);
    await pumpEditor(tester, _food(quantity: '400', servingQuantity: 40));
    expect(double.parse((await energy(tester)).controller!.text), 1840);
    await simple(tester);
    expect(double.parse((await energy(tester)).controller!.text), 184);
    await advanced(tester);
    expect(double.parse((await energy(tester)).controller!.text), 1840);
    await reopenPreferences(tester);
    expect(await preferences.getCustomMealNutrientsTotal(), isTrue);
  });

  for (final unit in ['g', 'ml']) {
    for (final useImperial in [false, true]) {
      for (final useKj in [false, true]) {
        for (final mode in ['per', 'total', 'simple']) {
          testWidgets(
            'basis round trip: $unit, imperial=$useImperial, kj=$useKj, $mode',
            (tester) async {
              imperial = useImperial;
              kilojoules = useKj;
              await pumpEditor(tester, _food(unit: unit));
              // No-op save or a full toggle cycle must not alter the density.
              if (mode != 'per') {
                await toggleTotal(tester);
                expect(
                  double.parse((await energy(tester)).controller!.text),
                  closeTo(kilojoules ? 1154.8 : 276, kilojoules ? 3 : 0.7),
                );
                await per100(tester, unit);
                expect(
                  double.parse((await energy(tester)).controller!.text),
                  closeTo(kilojoules ? 1924.6 : 460, 0.001),
                );
                await simple(tester);
                expect(
                  double.parse((await energy(tester)).controller!.text),
                  closeTo(kilojoules ? 1154.8 : 276, kilojoules ? 3 : 0.7),
                );
                if (mode == 'total') {
                  await advanced(tester);
                  await toggleTotal(tester);
                }
              }
              final reopened = await saveAndReopen(tester);
              expectDensity(reopened);
              expect(double.parse(reopened.mealQuantity!), 60);
              expect(reopened.servingQuantity, 60);
              expect(reopened.servingSize, '1 portion (60 $unit)');
              expect(reopened.mealUnit, unit);
              expect(reopened.servingUnit, unit);
              expect(
                kcalForQuantity(1, 'serving', reopened),
                closeTo(276, 0.7),
              );
              await reopenPreferences(tester);
              expect(
                await preferences.getCustomMealNutrientsTotal(),
                mode == 'total',
              );
              await pumpEditor(tester, reopened);
              expect(
                double.parse((await energy(tester)).controller!.text),
                closeTo(
                  mode == 'total'
                      ? (kilojoules ? 1154.76 : 276)
                      : (kilojoules ? 1924.6 : 460),
                  0.7,
                ),
              );
              final again = await saveAndReopen(tester);
              expectDensity(again);
            },
          );
        }
      }
    }
  }

  for (final mode in ['simple', 'total']) {
    testWidgets('small-serving kJ $mode save preserves energy density', (
      tester,
    ) async {
      kilojoules = true;
      await pumpEditor(tester, _food(quantity: '0.1'));
      if (mode == 'simple') {
        await simple(tester);
      } else {
        await toggleTotal(tester);
      }
      expect(
        double.parse((await energy(tester)).controller!.text),
        closeTo(1.9246, 1e-10),
      );
      final reopened = await saveAndReopen(tester, acceptWarning: true);
      // The existing kJ display rounds 1924.64 to 1924.6 before scaling.
      expect(reopened.nutriments.energyKcal100, closeTo(460, 0.01));
      expect(kcalForQuantity(1, 'serving', reopened), closeTo(0.46, 0.00001));
      await pumpEditor(tester, reopened);
      expect(
        double.parse((await energy(tester)).controller!.text),
        closeTo(mode == 'total' ? 1.9246 : 1924.6, 1e-8),
      );
      expect(
        (await saveAndReopen(tester)).nutriments.energyKcal100,
        closeTo(460, 0.01),
      );
    });
  }

  for (final mode in ['simple', 'total']) {
    testWidgets(
      'small-serving kJ to kcal mid-edit in $mode preserves energy density',
      (tester) async {
        kilojoules = true;
        await pumpEditor(tester, _food(quantity: '0.1'));
        if (mode == 'simple') {
          await simple(tester);
        } else {
          await toggleTotal(tester);
        }
        expect(
          double.parse((await energy(tester)).controller!.text),
          closeTo(1.9246, 1e-10),
        );
        final provider = tester
            .element(find.byType(EditMealScreen))
            .read<EnergyUnitProvider>();
        provider.updateUsesKilojoules(false);
        kilojoules = false;
        await tester.pumpAndSettle();
        final reopened = await saveAndReopen(tester, acceptWarning: true);
        // The initial kJ display still rounds 1924.64 to 1924.6.
        expect(reopened.nutriments.energyKcal100, closeTo(460, 0.01));
        expect(kcalForQuantity(1, 'serving', reopened), closeTo(0.46, 0.00001));
      },
    );
  }

  for (final edit in ['unchanged', 'quantity', 'unit']) {
    testWidgets('legacy text-only serving after $edit controls', (
      tester,
    ) async {
      final legacy = MealEntity(
        code: 'legacy-serving',
        name: 'Text-only serving food',
        url: null,
        mealQuantity: null,
        mealUnit: null,
        servingQuantity: null,
        servingUnit: null,
        servingSize: '2 Tbsp (32 g)',
        nutriments: _food().nutriments,
        source: MealSourceEntity.custom,
        detailed: true,
      );
      await tester.runAsync(
        () => library.saveCustomMeal(MealDBO.fromMealEntity(legacy)),
      );
      await pumpEditor(
        tester,
        MealEntity.fromMealDBO(library.getAllCustomMeals().single),
      );
      if (edit == 'quantity') {
        await tester.enterText(
          await field(
            tester,
            '${l10nEn.servingSizeLabelMetric} (${l10nEn.gramMilliliterUnit})',
          ),
          '16',
        );
      } else if (edit == 'unit') {
        await field(
          tester,
          '${l10nEn.mealSizeLabel} (${l10nEn.gramMilliliterUnit})',
        );
        await tester.tap(find.text(l10nEn.gramUnit).first);
        await tester.pumpAndSettle();
      }
      final reopened = await saveAndReopen(tester);
      expectDensity(reopened);
      if (edit == 'unchanged') {
        expect(reopened.servingQuantity, isNull);
        expect(reopened.servingSize, '2 Tbsp (32 g)');
        expect(reopened.scalableServingQuantity, 32);
        expect(kcalForQuantity(1, 'serving', reopened), closeTo(147.2, 1e-8));
        await pumpEditor(tester, reopened);
        final again = await saveAndReopen(tester);
        expect(again.servingSize, '2 Tbsp (32 g)');
        expect(again.scalableServingQuantity, 32);
      } else {
        expect(reopened.servingSize, isNull);
        expect(reopened.servingQuantity, edit == 'quantity' ? 16 : isNull);
        expect(reopened.servingUnit, edit == 'unit' ? 'g' : 'g/ml');
      }
    });
  }

  testWidgets('serving edit changes serving totals once, not per-100 density', (
    tester,
  ) async {
    await pumpEditor(tester, _food());
    await tester.enterText(
      await field(tester, '${l10nEn.servingSizeLabelMetric} (g)'),
      '30',
    );
    await simple(tester);
    expect(double.parse((await energy(tester)).controller!.text), 138);
    expect(find.textContaining('Per 30 g'), findsWidgets);
    final reopened = await saveAndReopen(tester);
    expectDensity(reopened);
    expect(reopened.servingQuantity, 30);
    expect(
      reopened.servingSize,
      isNull,
    ); // Detail constructs the new 30 g label.
    expect(convertQuantityToBaseUnit(1, 'serving', reopened), 30);
    expect(reopened.mealQuantity, '60');
    expect(kcalForQuantity(1, 'serving', reopened), 138);
    expect(kcalForQuantity(2, 'serving', reopened), 276);

    final logged = _AddIntake();
    final detail = MealDetailBloc(
      logged,
      _AddDay(),
      _Goal(),
      _Macros(),
      _Day(),
      _Products(),
      _Cache(),
    );
    addTearDown(detail.close);
    detail.add(
      UpdateKcalEvent(
        meal: reopened,
        totalQuantity: '2',
        selectedUnit: 'serving',
      ),
    );
    final quantity = TextEditingController(text: '2');
    addTearDown(quantity.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: MealDetailBottomSheet(
            product: reopened,
            day: DateTime(2026, 10, 31),
            intakeTypeEntity: IntakeTypeEntity.breakfast,
            quantityTextController: quantity,
            onQuantityOrUnitChanged: (_, _) {},
            mealDetailBloc: detail,
            selectedUnit: 'serving',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('${l10nEn.servingLabel} (30.0 g)'), findsWidgets);
    expect(find.textContaining('60 g'), findsNothing);
    await detail.addIntake(
      tester.element(find.byType(Scaffold)),
      'serving',
      detail.state.totalQuantityConverted,
      IntakeTypeEntity.breakfast,
      reopened,
      DateTime(2026, 10, 31),
    );
    expect(logged.intakes.single.amount, 60);
    expect(logged.intakes.single.totalKcal, 276);
  });

  for (final unit in ['g', 'ml']) {
    testWidgets(
      'formatting-only imperial $unit edits retain exact metric sizes',
      (tester) async {
        imperial = true;
        await pumpEditor(tester, _food(unit: unit));
        final suffix = unit == 'g' ? l10nEn.ozUnit : l10nEn.flOzUnit;
        for (final label in [
          l10nEn.mealSizeLabel,
          l10nEn.servingSizeLabelMetric,
        ]) {
          final finder = await field(tester, '$label ($suffix)');
          final text = tester.widget<TextFormField>(finder).controller!.text;
          await tester.enterText(finder, '${text}0');
        }
        await toggleTotal(tester);
        expect(double.parse((await energy(tester)).controller!.text), 276);
        await simple(tester);
        expect(double.parse((await energy(tester)).controller!.text), 276);
        final reopened = await saveAndReopen(tester);
        expect(double.parse(reopened.mealQuantity!), 60);
        expect(reopened.servingQuantity, 60);
        expect(reopened.servingSize, '1 portion (60 $unit)');
        expectDensity(reopened);
      },
    );
  }

  testWidgets('genuine imperial edits convert once for basis and save', (
    tester,
  ) async {
    imperial = true;
    await pumpEditor(tester, _food());
    await toggleTotal(tester);
    await tester.enterText(
      await field(tester, '${l10nEn.mealSizeLabel} (${l10nEn.ozUnit})'),
      '3',
    );
    await tester.enterText(
      await field(
        tester,
        '${l10nEn.servingSizeLabelMetric} (${l10nEn.ozUnit})',
      ),
      '1',
    );
    await tester.pumpAndSettle();
    expect(
      double.parse((await energy(tester)).controller!.text),
      closeTo(391.2231, 0.000001),
    );
    await simple(tester);
    expect(
      double.parse((await energy(tester)).controller!.text),
      closeTo(130.4077, 0.000001),
    );
    final reopened = await saveAndReopen(tester);
    expect(double.parse(reopened.mealQuantity!), closeTo(85.0485, 1e-10));
    expect(reopened.servingQuantity, 28.3495);
    expect(reopened.servingSize, isNull);
    expect(convertQuantityToBaseUnit(2, 'serving', reopened), 56.699);
    expectDensity(reopened);
  });

  testWidgets('imperial unit change cannot reuse the old gram scalar', (
    tester,
  ) async {
    imperial = true;
    await pumpEditor(tester, _food());
    await field(tester, '${l10nEn.mealSizeLabel} (${l10nEn.ozUnit})');
    await tester.tap(find.text(l10nEn.flOzUnit).first);
    await tester.pumpAndSettle();
    await simple(tester);
    expect(
      double.parse((await energy(tester)).controller!.text),
      closeTo(288.400772, 0.000001),
    );
    final reopened = await saveAndReopen(tester);
    expect(double.parse(reopened.mealQuantity!), closeTo(62.69582, 0.000001));
    expect(reopened.servingQuantity, closeTo(62.69582, 0.000001));
    expect(reopened.mealUnit, 'ml');
    expect(reopened.servingUnit, 'ml');
    expect(reopened.servingSize, isNull);
    expectDensity(reopened);
  });

  testWidgets(
    'editing package total size rescales populated fields, not density',
    (tester) async {
      await pumpEditor(tester, _food());
      await toggleTotal(tester);
      await tester.enterText(
        await field(tester, '${l10nEn.mealSizeLabel} (g)'),
        '120',
      );
      await tester.pumpAndSettle();
      expect(double.parse((await energy(tester)).controller!.text), 552);
      expect(find.text('Package total (120 g)'), findsWidgets);
      final reopened = await saveAndReopen(tester);
      expectDensity(reopened);
      expect(reopened.mealQuantity, '120');
      expect(reopened.servingQuantity, 60);
    },
  );

  testWidgets(
    'explicit nutrition base edit reinterprets input with immediate label',
    (tester) async {
      imperial = true;
      await pumpEditor(tester, _food());
      await tester.enterText(
        await field(tester, '${l10nEn.baseQuantityLabel} (g)'),
        '60',
      );
      await tester.pumpAndSettle();
      expect(double.parse((await energy(tester)).controller!.text), 460);
      expect(find.text('Per 60 g'), findsWidgets);
      for (final (label, value) in [
        ('${l10nEn.mealEnergyLabel} (${l10nEn.kcalLabel})', '276'),
        (l10nEn.mealCarbsLabel, '36'),
        (l10nEn.mealFatLabel, '12'),
        (l10nEn.mealProteinLabel, '6'),
        (l10nEn.fiberLabel, '4.8'),
      ]) {
        await tester.enterText(await field(tester, label), value);
      }
      final reopened = await saveAndReopen(tester);
      expect(reopened.nutriments.energyKcal100, 460);
      expect(reopened.nutriments.carbohydrates100, 60);
      expect(reopened.nutriments.fiber100, 8);
      // Untouched label numbers are intentionally reinterpreted at the new basis.
      expect(reopened.nutriments.sodium100, closeTo(166.6667, 0.0001));
    },
  );

  testWidgets('edited package totals normalize once on save and reopen', (
    tester,
  ) async {
    await pumpEditor(tester, _food());
    await toggleTotal(tester);
    for (final (label, value) in [
      ('${l10nEn.mealEnergyLabel} (${l10nEn.kcalLabel})', '300'),
      (l10nEn.mealCarbsLabel, '40'),
      (l10nEn.mealFatLabel, '12'),
      (l10nEn.mealProteinLabel, '8'),
    ]) {
      await tester.enterText(await field(tester, label), value);
    }
    final reopened = await saveAndReopen(tester);
    expect(reopened.nutriments.energyKcal100, 500);
    expect(reopened.nutriments.carbohydrates100, closeTo(66.6667, 0.0001));
    expect(reopened.nutriments.fiber100, 8);
    expect(kcalForQuantity(1, 'serving', reopened), 300);
    await pumpEditor(tester, reopened);
    expect(double.parse((await energy(tester)).controller!.text), 300);
    await per100(tester, 'g');
    expect(double.parse((await energy(tester)).controller!.text), 500);
    await toggleTotal(tester);
    expect(double.parse((await energy(tester)).controller!.text), 300);
  });

  testWidgets(
    'kcal to kJ mid-edit composes with serving and package views once',
    (tester) async {
      await pumpEditor(tester, _food());
      await simple(tester);
      final provider = tester
          .element(find.byType(EditMealScreen))
          .read<EnergyUnitProvider>();
      provider.updateUsesKilojoules(true);
      kilojoules = true;
      await tester.pumpAndSettle();
      expect(
        double.parse((await energy(tester)).controller!.text),
        closeTo(1154.784, 1e-8),
      );
      await advanced(tester);
      await toggleTotal(tester);
      expect(
        double.parse((await energy(tester)).controller!.text),
        closeTo(1154.784, 1e-8),
      );
      expectDensity(await saveAndReopen(tester));
    },
  );

  testWidgets('zero package size cannot be saved as a package total', (
    tester,
  ) async {
    await pumpEditor(tester, _food());
    await toggleTotal(tester);
    await tester.enterText(
      await field(tester, '${l10nEn.mealSizeLabel} (g)'),
      '0',
    );
    await tester.tap(find.widgetWithText(FilledButton, l10nEn.buttonSaveLabel));
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.mealNutritionBasisInvalid), findsOneWidget);
    expect(find.byType(EditMealScreen), findsOneWidget);
    expect(library.getAllCustomMeals(), isEmpty);
  });

  for (final invalid in ['0', '1..']) {
    testWidgets(
      'invalid nutrition basis $invalid cannot save or destroy the original food',
      (tester) async {
        await tester.runAsync(
          () => library.saveCustomMeal(MealDBO.fromMealEntity(_food())),
        );
        await pumpEditor(tester, _food());
        await tester.enterText(
          await field(tester, '${l10nEn.baseQuantityLabel} (g)'),
          invalid,
        );
        await tester.tap(
          find.widgetWithText(FilledButton, l10nEn.buttonSaveLabel),
        );
        await tester.pumpAndSettle();
        expect(find.text(l10nEn.mealNutritionBasisInvalid), findsOneWidget);
        expect(find.byType(EditMealScreen), findsOneWidget);
        expectDensity(
          MealEntity.fromMealDBO(library.getAllCustomMeals().single),
        );
      },
    );
  }

  testWidgets(
    'simple shows actual 60g serving totals and preserves density and sizes',
    (tester) async {
      await pumpEditor(tester, _food());
      await simple(tester);
      expect(double.parse((await energy(tester)).controller!.text), 276);
      expect(find.textContaining('Per 60 g'), findsWidgets);
      final reopened = await saveAndReopen(tester);
      expect(reopened.nutriments.energyKcal100, closeTo(460, 0.001));
      expect(reopened.nutriments.fiber100, closeTo(8, 0.001));
      expect(reopened.mealQuantity, '60');
      expect(reopened.servingQuantity, 60);
    },
  );

  testWidgets('basis labels remain readable on a narrow large-text form', (
    tester,
  ) async {
    await pumpEditor(
      tester,
      _food(),
      size: const Size(390, 844),
      textScale: 1.6,
    );
    await toggleTotal(tester);
    expect(find.text('Package total (60 g)'), findsWidgets);
    await simple(tester);
    await energy(tester);
    expect(find.textContaining('Per 60 g'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('imperial sizes still label nutrition per metric 100g', (
    tester,
  ) async {
    imperial = true;
    await pumpEditor(tester, _food());
    expect(double.parse((await energy(tester)).controller!.text), 460);
    expect(find.text('Per 100 g'), findsWidgets);
    expect(find.text('Per 100 oz'), findsNothing);
  });

  testWidgets(
    'package total displays 276 kcal for 60g and reopens with canonical density',
    (tester) async {
      await pumpEditor(tester, _food());
      expect(double.parse((await energy(tester)).controller!.text), 460);
      expect(find.text('Per 100 g'), findsWidgets);
      await toggleTotal(tester);
      expect(double.parse((await energy(tester)).controller!.text), 276);
      final reopened = await saveAndReopen(tester);
      expect(reopened.nutriments.energyKcal100, closeTo(460, 0.001));
      expect(reopened.nutriments.fiber100, closeTo(8, 0.001));
      await pumpEditor(tester, reopened);
      expect(double.parse((await energy(tester)).controller!.text), 276);
    },
  );
}

class _Config extends Fake implements GetConfigUsecase {
  _Config(this.imperial);
  final bool imperial;
  @override
  Future<ConfigEntity> getConfig() async => ConfigEntity(
    true,
    true,
    false,
    AppThemeEntity.system,
    usesImperialFoodUnits: imperial,
  );
}

class _Favourites extends Fake implements FavouriteMealRepository {
  @override
  Future<void> moveFavourite(MealEntity previous, MealEntity updated) async {}
}

class _Intakes extends Fake implements IntakeRepository {}

class _AddIntake extends Fake implements AddIntakeUsecase {
  final intakes = <IntakeEntity>[];
  @override
  Future<void> addIntake(IntakeEntity intake) async => intakes.add(intake);
}

class _AddDay extends Fake implements AddTrackedDayUsecase {
  @override
  Future<bool> hasTrackedDay(DateTime day) async => true;
  @override
  Future<void> addDayCaloriesTracked(
    DateTime day,
    double caloriesTracked,
  ) async {}
  @override
  Future<void> addDayMacrosTracked(
    DateTime day, {
    double? carbsTracked,
    double? fatTracked,
    double? proteinTracked,
  }) async {}
}

class _Goal extends Fake implements GetKcalGoalUsecase {}

class _Macros extends Fake implements GetMacroGoalUsecase {}

class _Day extends Fake implements GetTrackedDayUsecase {
  @override
  Future<TrackedDayEntity?> getTrackedDay(DateTime day) async => null;
}

class _Products extends Fake implements ProductsRepository {}

class _Cache extends Fake implements RemoteSearchCacheDataSource {
  @override
  Future<void> touch(String code) async {}
}
