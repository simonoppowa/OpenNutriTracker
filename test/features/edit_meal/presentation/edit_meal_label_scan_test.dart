import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/favourite_meal_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/edit_meal/domain/usecase/read_nutrition_label_usecase.dart';
import 'package:opennutritracker/features/edit_meal/presentation/bloc/edit_meal_bloc.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/features/edit_meal/presentation/widgets/label_scan_button.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../helpers/test_l10n.dart';

/// "Read nutrition label" on the custom-meal form: offered only while AI
/// meal assistance can read a photo, and a reading fills the form with
/// what the label printed.
void main() {
  final getIt = GetIt.instance;
  late _RecordingCustomMealDataSource dataSource;

  const aiOn = {
    'AiProviderTag': 'anthropic',
    'AiApiKeyTag.anthropic': 'sk-ant',
    'AiTermsAcceptedTag': 'true',
  };

  void registerLabels(Map<String, String> stored) {
    getIt.registerLazySingleton<ReadNutritionLabelUseCase>(
      () => ReadNutritionLabelUseCase(
        AiCredentialStorage(_MapStorage(stored)),
        MockClient((_) async => http.Response('', 500)),
      ),
    );
  }

  setUp(() {
    dataSource = _RecordingCustomMealDataSource();
    getIt.registerFactory<EditMealBloc>(
      () => EditMealBloc(
        _FakeGetConfigUsecase(),
        dataSource,
        _FakeConfigRepository(),
        _FakeFavouriteMealRepository(),
        _RecordingIntakeRepository(),
      ),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  MealEntity meal({
    String? code = 'uuid-crispbread',
    MealSourceEntity source = MealSourceEntity.custom,
  }) => MealEntity(
    code: code,
    name: 'Crispbread',
    url: null,
    mealQuantity: '100',
    mealUnit: 'gml',
    servingQuantity: 100,
    servingUnit: 'gml',
    servingSize: '',
    nutriments: const MealNutrimentsEntity(
      energyKcal100: null,
      carbohydrates100: null,
      fat100: null,
      proteins100: null,
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
    ),
    source: source,
  );

  /// Opens the editor the way the custom meal list does (`editOnly`).
  Future<void> pumpEditor(WidgetTester tester, MealEntity meal) async {
    dataSource.library.add(MealDBO.fromMealEntity(meal));
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<EnergyUnitProvider>(
        create: (_) => EnergyUnitProvider(),
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
                  DateTime(2026, 10, 18),
                  meal,
                  IntakeTypeEntity.breakfast,
                  false,
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
  }

  final readLabel = find.byTooltip(l10nEn.customMealLabelScanButton);

  testWidgets('offered on a custom meal while AI meal assistance is on', (
    tester,
  ) async {
    registerLabels(aiOn);
    await pumpEditor(tester, meal());

    expect(readLabel, findsOneWidget);
  });

  testWidgets('not offered while AI meal assistance is hidden', (tester) async {
    registerLabels({...aiOn, 'AiAssistHiddenTag': 'true'});
    await pumpEditor(tester, meal());

    expect(readLabel, findsNothing);
  });

  testWidgets('not offered on a database food', (tester) async {
    registerLabels(aiOn);
    getIt.registerLazySingleton<CacheManager>(_FakeCacheManager.new);
    await pumpEditor(tester, meal(source: MealSourceEntity.off));

    expect(find.byType(LabelScanButton), findsNothing);
  });

  testWidgets('a reading fills the form per 100, and saves', (tester) async {
    registerLabels(aiOn);
    await pumpEditor(tester, meal());

    tester
        .widget<LabelScanButton>(find.byType(LabelScanButton))
        .onRead(
          const NutritionLabelReading(
            name: 'Rye crispbread',
            brand: 'Finn Crisp',
            barcode: '6410500090014',
            servingGrams: 10,
            per100: {'energyKcal': 350, 'fat': 2.5, 'sodium': 480},
          ),
        );
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.customMealLabelScanFilled(7)), findsOneWidget);
    // Per 100, so the form went to Advanced with base quantity 100.
    expect(
      find.widgetWithText(
        TextFormField,
        '${l10nEn.baseQuantityLabel} (${l10nEn.gramMilliliterUnit})',
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, l10nEn.buttonSaveLabel));
    await tester.pumpAndSettle();

    final (saved, _) = dataSource.saves.single;
    expect(saved.name, 'Rye crispbread');
    expect(saved.brands, 'Finn Crisp');
    expect(saved.code, '6410500090014');
    expect(saved.servingQuantity, 10);
    expect(saved.nutriments.energyKcal100, 350);
    expect(saved.nutriments.fat100, 2.5);
    expect(saved.nutriments.sodium100, 480);
  });

  testWidgets('values typed as totals that the label does not print are '
      'cleared, not read as per 100', (tester) async {
    registerLabels(aiOn);
    await pumpEditor(tester, meal());
    void read(NutritionLabelReading reading) => tester
        .widget<LabelScanButton>(find.byType(LabelScanButton))
        .onRead(reading);

    read(const NutritionLabelReading(per100: {'fat': 2.5, 'sodium': 480}));
    await tester.pumpAndSettle();
    final total = find.text(l10nEn.mealNutrientsTotalLabel);
    await tester.ensureVisible(total);
    await tester.tap(total);
    await tester.pumpAndSettle();

    read(const NutritionLabelReading(per100: {'energyKcal': 350}));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10nEn.buttonSaveLabel));
    await tester.pumpAndSettle();

    final saved = dataSource.saves.single.$1.nutriments;
    expect(saved.energyKcal100, 350);
    expect(saved.fat100, isNull);
    expect(saved.sodium100, isNull);
  });

  testWidgets('a barcode already in the form stays', (tester) async {
    registerLabels(aiOn);
    await pumpEditor(tester, meal(code: '4006381333931'));

    tester
        .widget<LabelScanButton>(find.byType(LabelScanButton))
        .onRead(
          const NutritionLabelReading(
            barcode: '6410500090014',
            per100: {'energyKcal': 350},
          ),
        );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10nEn.buttonSaveLabel));
    await tester.pumpAndSettle();

    expect(dataSource.saves.single.$1.code, '4006381333931');
  });
}

class _MapStorage implements FlutterSecureStorage {
  final Map<String, String> values;

  _MapStorage(this.values);

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _RecordingCustomMealDataSource implements CustomMealDataSource {
  final saves = <(MealDBO, MealDBO?)>[];
  final library = <MealDBO>[];

  @override
  List<MealDBO> getAllCustomMeals() => library;

  /// When set, every save waits for it, standing in for a slow disk write.
  Completer<void>? gate;

  @override
  Future<void> saveCustomMeal(MealDBO mealDBO, {MealDBO? previous}) async {
    saves.add((mealDBO, previous));
    await gate?.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _RecordingIntakeRepository implements IntakeRepository {
  final moves = <(String, MealDBO)>[];

  @override
  Future<int> moveCustomMealInEveryProfile({
    required String fromMealKey,
    required MealDBO toMeal,
  }) async {
    moves.add((fromMealKey, toMeal));
    return 0;
  }

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
  @override
  Future<String?> getCustomMealFormMode() async =>
      CustomMealFormMode.simple.name;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

/// #1307 moves a favourite along with the edit; nothing is starred here.
class _FakeFavouriteMealRepository implements FavouriteMealRepository {
  @override
  Future<void> moveFavourite(MealEntity previous, MealEntity updated) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeCacheManager implements CacheManager {
  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) => const Stream<FileResponse>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}
