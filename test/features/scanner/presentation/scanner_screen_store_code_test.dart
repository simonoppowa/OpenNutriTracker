import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/features/scanner/domain/store_barcode_check.dart';
import 'package:opennutritracker/features/scanner/domain/usecase/search_product_by_barcode_usecase.dart';
import 'package:opennutritracker/features/scanner/presentation/scanner_bloc.dart';
import 'package:opennutritracker/features/scanner/scanner_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../helpers/test_l10n.dart';

final _otherStoresProduct = MealEntity(
  code: '20697112',
  name: 'Milk chocolate de Noël',
  brands: 'Favorina',
  url: null,
  mealQuantity: '100',
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: 'g',
  servingSize: null,
  source: MealSourceEntity.off,
  nutriments: const MealNutrimentsEntity(
    energyKcal100: 540,
    carbohydrates100: 56,
    fat100: 31,
    proteins100: 7,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
);

void main() {
  final getIt = GetIt.instance;
  late _FakeConfigDataSource config;

  setUp(() {
    config = _FakeConfigDataSource();
    getIt.registerFactory<ScannerBloc>(
      () => ScannerBloc(
        _FakeSearchUseCase(_otherStoresProduct),
        _FakeGetConfigUsecase(),
      ),
    );
    getIt.registerLazySingleton(() => StoreBarcodeCheck(config));
    getIt.registerLazySingleton<CacheManager>(_FakeCacheManager.new);
  });

  tearDown(() => getIt.reset());

  group('logging flow', () {
    final pushed = <RouteSettings>[];

    Future<void> scan(WidgetTester tester) async {
      pushed.clear();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          onGenerateRoute: (settings) {
            pushed.add(settings);
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => Scaffold(body: Text('${settings.name}')),
            );
          },
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  settings: RouteSettings(
                    arguments: ScannerScreenArguments(
                      DateTime(2026, 10, 19),
                      IntakeTypeEntity.snack,
                      initialBarcode: '20697112',
                    ),
                  ),
                  builder: (_) => const ScannerScreen(),
                ),
              ),
              child: const Text('open scanner'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open scanner'));
      await tester.pumpAndSettle();
    }

    testWidgets('yes keeps the product and remembers the code', (tester) async {
      await scan(tester);
      expect(find.text(l10nEn.storeCodeConfirmTitle), findsOneWidget);

      await tester.tap(find.text(l10nEn.storeCodeConfirmYes));
      await tester.pumpAndSettle();

      expect(pushed.single.name, NavigationOptions.mealDetailRoute);
      expect(
        (pushed.single.arguments as MealDetailScreenArguments).mealEntity.name,
        'Milk chocolate de Noël',
      );
      expect(config.config.confirmedStoreBarcodes, ['20697112']);
    });

    testWidgets('no opens a new own food with the code', (tester) async {
      await scan(tester);

      await tester.tap(find.text(l10nEn.storeCodeConfirmNo));
      await tester.pumpAndSettle();

      expect(pushed.single.name, NavigationOptions.editMealRoute);
      final args = pushed.single.arguments as EditMealScreenArguments;
      expect(args.barcode, '20697112');
      expect(args.scanLabelOnOpen, isTrue);
      expect(args.mealEntity.source, MealSourceEntity.custom);
      expect(args.mealEntity.name, isNull);
      expect(config.config.confirmedStoreBarcodes, isNull);
    });

    testWidgets('a confirmed code is not asked again', (tester) async {
      config.config.confirmedStoreBarcodes = ['20697112'];

      await scan(tester);

      expect(find.text(l10nEn.storeCodeConfirmTitle), findsNothing);
      expect(pushed.single.name, NavigationOptions.mealDetailRoute);
    });
  });

  group('recipe ingredient picker', () {
    MealEntity? picked;
    var returned = false;

    Future<void> scan(WidgetTester tester) async {
      picked = null;
      returned = false;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  picked = await Navigator.of(context).push<MealEntity>(
                    MaterialPageRoute(
                      settings: RouteSettings(
                        arguments: ScannerScreenArguments.pick(
                          initialBarcode: '20697112',
                        ),
                      ),
                      builder: (_) => const ScannerScreen(),
                    ),
                  );
                  returned = true;
                },
                child: const Text('open scanner'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open scanner'));
      await tester.pumpAndSettle();
    }

    testWidgets('asks too, and yes hands the product back', (tester) async {
      await scan(tester);
      expect(find.text(l10nEn.storeCodeConfirmTitle), findsOneWidget);

      await tester.tap(find.text(l10nEn.storeCodeConfirmYes));
      await tester.pumpAndSettle();

      expect(picked?.code, '20697112');
    });

    testWidgets('no hands nothing back and says why', (tester) async {
      await scan(tester);

      await tester.tap(find.text(l10nEn.storeCodeConfirmNo));
      await tester.pumpAndSettle();

      expect(returned, isTrue);
      expect(picked, isNull);
      expect(find.text(l10nEn.storeCodeRejectedInPicker), findsOneWidget);
    });
  });
}

class _FakeConfigDataSource implements ConfigDataSource {
  ConfigDBO config = ConfigDBO(false, false, false, AppThemeDBO.system);

  @override
  Future<ConfigDBO> getConfig() async => config;

  @override
  Future<void> addConfig(ConfigDBO configDBO) async => config = configDBO;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeSearchUseCase implements SearchProductByBarcodeUseCase {
  final MealEntity _result;

  _FakeSearchUseCase(this._result);

  @override
  Future<MealEntity> searchProductByBarcode(String barcode) async => _result;

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

class _FakeCacheManager implements CacheManager {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}
