import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/edit_meal/presentation/bloc/edit_meal_bloc.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/features/scanner/data/nutrition_label_scanner.dart';
import 'package:opennutritracker/features/scanner/data/text_recognizer.dart';
import 'package:opennutritracker/features/scanner/util/nutrition_label_parser.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../helpers/test_l10n.dart';

void main() {
  final getIt = GetIt.instance;
  var photosTaken = 0;

  void registerScanner(List<OcrLine> lines) {
    getIt.registerLazySingleton<NutritionLabelScanner>(
      () => NutritionLabelScanner(
        _FakeRecognizer(lines),
        pickImage: (_) async {
          photosTaken++;
          return '/tmp/label.jpg';
        },
        deletePhoto: (_) async {},
      ),
    );
  }

  setUp(() {
    photosTaken = 0;
    _FakeCustomMealDataSource.saved.clear();
    getIt.registerFactory<EditMealBloc>(
      () => EditMealBloc(
        _FakeGetConfigUsecase(),
        _FakeCustomMealDataSource(),
        _FakeConfigRepository(),
      ),
    );
    getIt.registerLazySingleton<CacheManager>(_FakeCacheManager.new);
  });

  tearDown(() async => getIt.reset());

  Future<void> pumpEditMeal(
    WidgetTester tester,
    EditMealScreenArguments arguments,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider<EnergyUnitProvider>(
        create: (_) => EnergyUnitProvider(),
        child: MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          onGenerateRoute: (settings) =>
              settings.name == NavigationOptions.mealDetailRoute
              ? MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => const Scaffold(body: Text('meal-detail')),
                )
              : MaterialPageRoute<void>(
                  settings: RouteSettings(
                    name: NavigationOptions.editMealRoute,
                    arguments: arguments,
                  ),
                  builder: (_) => const EditMealScreen(),
                ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String fieldText(WidgetTester tester, String label) {
    final field = tester.widget<TextField>(
      find.descendant(
        of: find.ancestor(
          of: find.textContaining(label),
          matching: find.byType(TextFormField),
        ),
        matching: find.byType(TextField),
      ),
    );
    return field.controller!.text;
  }

  final label = [
    _line('Brennwert 1O46 kJ / 25O kcal', 0.10),
    _line('Fett 9,5 g', 0.15),
    _line('Kohlenhydrate 30 g', 0.20),
    _line('davon Zucker 12 g', 0.25),
    _line('Eiweiß 8 g', 0.30),
    _line('Salz 0,5 g', 0.35),
  ];

  testWidgets('a scanned table fills the form and marks unsure values', (
    tester,
  ) async {
    registerScanner(label);
    await pumpEditMeal(
      tester,
      EditMealScreenArguments(
        DateTime(2026, 10, 19),
        MealEntity.empty(),
        IntakeTypeEntity.snack,
        false,
      ),
    );

    await tester.tap(find.text(l10nEn.labelScanAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.labelScanCamera));
    await tester.pumpAndSettle();

    expect(photosTaken, 1);
    expect(fieldText(tester, l10nEn.mealEnergyLabel), '250');
    expect(fieldText(tester, l10nEn.mealFatLabel), '9.5');
    expect(fieldText(tester, l10nEn.mealCarbsLabel), '30');
    expect(fieldText(tester, l10nEn.mealProteinLabel), '8');
    expect(fieldText(tester, l10nEn.sugarLabel), '12');
    expect(fieldText(tester, l10nEn.sodiumLabel), '200');
    expect(find.text(l10nEn.labelScanCheckField), findsOneWidget);
    expect(find.text(l10nEn.labelScanFilled('g')), findsOneWidget);
  });

  testWidgets('a cancelled photo leaves the form as it was', (tester) async {
    getIt.registerLazySingleton<NutritionLabelScanner>(
      () => NutritionLabelScanner(
        _FakeRecognizer(label),
        pickImage: (_) async => null,
      ),
    );
    await pumpEditMeal(
      tester,
      EditMealScreenArguments(
        DateTime(2026, 10, 19),
        MealEntity.empty(),
        IntakeTypeEntity.snack,
        false,
      ),
    );

    await tester.tap(find.text(l10nEn.labelScanAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.labelScanGallery));
    await tester.pumpAndSettle();

    expect(fieldText(tester, l10nEn.mealEnergyLabel), '');
    expect(find.text(l10nEn.labelScanCheckField), findsNothing);
  });

  testWidgets('a denied camera says the photo could not be read', (
    tester,
  ) async {
    getIt.registerLazySingleton<NutritionLabelScanner>(
      () => NutritionLabelScanner(
        _FakeRecognizer(label),
        pickImage: (_) async =>
            throw PlatformException(code: 'camera_access_denied'),
      ),
    );
    await pumpEditMeal(
      tester,
      EditMealScreenArguments(
        DateTime(2026, 10, 19),
        MealEntity.empty(),
        IntakeTypeEntity.snack,
        false,
      ),
    );

    await tester.tap(find.text(l10nEn.labelScanAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.labelScanCamera));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.labelScanFailed), findsOneWidget);
    expect(find.text(l10nEn.labelScanAction), findsOneWidget);
  });

  testWidgets('a device without text recognition says so', (tester) async {
    getIt.registerLazySingleton<NutritionLabelScanner>(
      () => NutritionLabelScanner(
        _FakeRecognizer(
          label,
          error: const TextRecognitionException(
            TextRecognitionFailure.unavailable,
          ),
        ),
        pickImage: (_) async => '/tmp/label.jpg',
        deletePhoto: (_) async {},
      ),
    );
    await pumpEditMeal(
      tester,
      EditMealScreenArguments(
        DateTime(2026, 10, 19),
        MealEntity.empty(),
        IntakeTypeEntity.snack,
        false,
      ),
    );

    await tester.tap(find.text(l10nEn.labelScanAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.labelScanCamera));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.labelScanUnavailable), findsOneWidget);
  });

  testWidgets('a photo without a table says so and fills nothing', (
    tester,
  ) async {
    registerScanner([_line('Zutaten: Wasser', 0.1)]);
    await pumpEditMeal(
      tester,
      EditMealScreenArguments(
        DateTime(2026, 10, 19),
        MealEntity.empty(),
        IntakeTypeEntity.snack,
        false,
      ),
    );

    await tester.tap(find.text(l10nEn.labelScanAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.labelScanCamera));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.labelScanNothingFound), findsOneWidget);
    expect(fieldText(tester, l10nEn.mealEnergyLabel), '');
  });

  testWidgets('opened for a product it asks for the photo and keeps the '
      'barcode', (tester) async {
    registerScanner(label);
    final meal = MealEntity.empty();
    await pumpEditMeal(
      tester,
      EditMealScreenArguments(
        DateTime(2026, 10, 19),
        meal,
        IntakeTypeEntity.snack,
        false,
        barcode: '4056489123456',
        scanLabelOnOpen: true,
      ),
    );

    expect(find.text(l10nEn.labelScanCamera), findsOneWidget);
    await tester.tap(find.text(l10nEn.labelScanCamera));
    await tester.pumpAndSettle();

    expect(fieldText(tester, l10nEn.customMealBarcodeLabel), '4056489123456');
    expect(fieldText(tester, l10nEn.mealEnergyLabel), '250');
  });

  testWidgets('after a scan without a barcode it offers to scan one', (
    tester,
  ) async {
    registerScanner(label);
    await pumpEditMeal(
      tester,
      EditMealScreenArguments(
        DateTime(2026, 10, 19),
        MealEntity.empty(),
        IntakeTypeEntity.snack,
        false,
      ),
    );

    await tester.tap(find.text(l10nEn.labelScanAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.labelScanCamera));
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(SnackBarAction, l10nEn.customMealBarcodeScanButton),
      findsOneWidget,
    );
  });

  group('barcode check digit on save', () {
    Future<void> saveWithBarcode(WidgetTester tester, String code) async {
      final meal = MealEntity.empty();
      await pumpEditMeal(
        tester,
        EditMealScreenArguments(
          DateTime(2026, 10, 19),
          meal,
          IntakeTypeEntity.snack,
          false,
          barcode: code,
        ),
      );
      await tester.enterText(
        find.descendant(
          of: find.ancestor(
            of: find.text(l10nEn.mealNameLabel),
            matching: find.byType(TextFormField),
          ),
          matching: find.byType(TextField),
        ),
        'Studenten-Futter',
      );
      await tester.tap(find.text(l10nEn.buttonSaveLabel));
      await tester.pumpAndSettle();
    }

    for (final code in ['40084016', '036000291453', '14056489123459']) {
      testWidgets('rejects $code, whose last digit does not match', (
        tester,
      ) async {
        await saveWithBarcode(tester, code);

        expect(find.text(l10nEn.barcodeInvalidCheckDigit), findsOneWidget);
        expect(_FakeCustomMealDataSource.saved, isEmpty);
      });
    }

    for (final code in ['40084015', '036000291452', '20697112']) {
      testWidgets('accepts $code', (tester) async {
        await saveWithBarcode(tester, code);

        expect(find.text(l10nEn.barcodeInvalidCheckDigit), findsNothing);
        expect(_FakeCustomMealDataSource.saved.single.code, code);
        expect(find.text('meal-detail'), findsOneWidget);
      });
    }
  });
}

OcrLine _line(String text, double y) =>
    OcrLine(text: text, x: 0.1, y: y, width: 0.5, height: 0.04);

class _FakeRecognizer implements TextRecognizer {
  final List<OcrLine> lines;
  final TextRecognitionException? error;

  _FakeRecognizer(this.lines, {this.error});

  @override
  Future<List<OcrLine>> recognize(String imagePath) async {
    if (error != null) throw error!;
    return lines;
  }
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
  @override
  Future<String?> getCustomMealFormMode() async =>
      CustomMealFormMode.simple.name;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeCustomMealDataSource implements CustomMealDataSource {
  static final saved = <MealDBO>[];

  @override
  Future<void> saveCustomMeal(MealDBO mealDBO) async => saved.add(mealDBO);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeCacheManager implements CacheManager {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}
