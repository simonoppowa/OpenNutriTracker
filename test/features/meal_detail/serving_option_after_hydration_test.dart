import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_dto.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../helpers/test_l10n.dart';

// #1216: "Seabrook sea salted crisps" opened from the search list shows
// "N/A" in the unit dropdown, and when the user picks the 31.8 g serving
// entry the selection vanishes.
//
// The shapes below are what Open Food Facts returned on 2026-09-18 for the
// two records that query surfaces: the Search-a-licious hit is the thin
// projection the app lists (no serving_*, no product_quantity — see
// `OFFConst._searchReturnFields`), and the v2 product record is what
// hydration swaps in once the detail screen is open.

/// Search-a-licious hit for 0080457761112. No `quantity`, so the entity's
/// `mealUnit` is null and the dropdown opens on "N/A (g/ml)".
const _seabrookCrispsSearchHit = <String, dynamic>{
  'code': '0080457761112',
  'brands': ['seabrook'],
  'product_name': 'Seabrook sea salted crisps',
  'product_name_en': 'Seabrook sea salted crisps',
  'countries_tags': ['en:united-kingdom'],
  'popularity_key': 12,
  'nutriments': {
    'carbohydrates_100g': 55.9,
    'energy-kcal_100g': 514,
    'energy-kj_100g': 2130,
    'fat_100g': 28.9,
    'proteins_100g': 5.7,
    'salt_100g': 1.32,
    'saturated-fat_100g': 2.8,
    'sodium_100g': 0.528,
    'sugars_100g': 0.4,
  },
};

/// v2 product record for 0080457761112: serving 31.8 g, no package quantity.
const _seabrookCrispsProduct = <String, dynamic>{
  'code': '0080457761112',
  'brands': 'seabrook',
  'product_name': 'Seabrook sea salted crisps',
  'product_name_en': 'Seabrook sea salted crisps',
  'serving_quantity': 31.8,
  'serving_quantity_unit': 'g',
  'serving_size': '31.8g',
  'nutriments': {
    'carbohydrates_100g': 55.9,
    'carbohydrates_serving': 17.8,
    'energy-kcal_100g': 514,
    'energy-kcal_serving': 163,
    'fat_100g': 28.9,
    'fat_serving': 9.19,
    'proteins_100g': 5.7,
    'proteins_serving': 1.81,
    'salt_100g': 1.32,
    'saturated-fat_100g': 2.8,
    'sodium_100g': 0.528,
    'sugars_100g': 0.4,
  },
};

/// Search-a-licious hit for 5016451062110, the multipack. It carries a
/// `quantity` of "6 x 25g", so the thin entity already reads as solid.
const _seabrookMultipackSearchHit = <String, dynamic>{
  'code': '5016451062110',
  'brands': ['Seabrook'],
  'quantity': '6 x 25g',
  'product_name': 'Seabrook sea salt',
  'product_name_en': 'Seabrook sea salt',
  'countries_tags': ['en:united-kingdom'],
  'popularity_key': 22950000024,
  'nutriments': {
    'carbohydrates_100g': 52.6,
    'energy-kcal_100g': 500,
    'fat_100g': 30.4,
    'proteins_100g': 5.9,
    'salt_100g': 1.3,
    'saturated-fat_100g': 2.7,
    'sodium_100g': 0.52,
    'sugars_100g': 0.2,
  },
};

/// v2 product record for 5016451062110: a package quantity but no serving,
/// and a different product name from the search index.
const _seabrookMultipackProduct = <String, dynamic>{
  'code': '5016451062110',
  'brands': 'Seabrook',
  'product_name': 'SEA SALTED POTATO CRISPS',
  'product_name_en': 'SEA SALTED POTATO CRISPS',
  'product_quantity': 150,
  'quantity': '6 x 25g',
  'nutriments': {
    'carbohydrates_100g': 52.6,
    'energy-kcal_100g': 500,
    'fat_100g': 30.4,
    'proteins_100g': 5.9,
    'salt_100g': 1.3,
    'saturated-fat_100g': 2.7,
    'sodium_100g': 0.52,
    'sugars_100g': 0.2,
  },
};

MealEntity _thin(Map<String, dynamic> hit) =>
    MealEntity.fromOFFProduct(OFFProductDTO.fromJson(hit));

MealEntity _full(Map<String, dynamic> product) =>
    MealEntity.fromOFFProduct(OFFProductDTO.fromJson(product), detailed: true);

void main() {
  final getIt = GetIt.instance;
  MealDetailBloc? bloc;
  late Completer<MealEntity> hydration;

  setUp(() {
    bloc = null;
    getIt.registerLazySingleton<MealDetailBloc>(
      () => bloc = MealDetailBloc(
        _FakeAddIntakeUsecase(),
        _FakeAddTrackedDayUsecase(),
        _FakeGetKcalGoalUsecase(),
        _FakeGetMacroGoalUsecase(),
        _FakeGetTrackedDayUsecase(),
        _FakeProductsRepository(() => hydration.future),
        _FakeRemoteSearchCacheDataSource(),
      ),
    );
    getIt.registerLazySingleton<GetConfigUsecase>(_FakeGetConfigUsecase.new);
    getIt.registerLazySingleton<GetIntakeUsecase>(_FakeGetIntakeUsecase.new);
    getIt.registerLazySingleton<CacheManager>(_FakeCacheManager.new);
    getIt.registerLazySingleton<HomeBloc>(_FakeHomeBloc.new);
    getIt.registerLazySingleton<DiaryBloc>(_FakeDiaryBloc.new);
    getIt.registerLazySingleton<CalendarDayBloc>(_FakeCalendarDayBloc.new);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pumpMealDetail(WidgetTester tester, MealEntity meal) async {
    // Created here, inside the test body, not in setUp: a Completer made
    // outside the FakeAsync zone completes on the real event loop, which
    // `tester.pump` never runs, so hydration would land only after the
    // test had already failed.
    hydration = Completer<MealEntity>();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Route<void> routeFor(RouteSettings settings) => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const MealDetailScreen(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<EnergyUnitProvider>(
        create: (_) => EnergyUnitProvider(),
        child: MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          initialRoute: NavigationOptions.mealDetailRoute,
          onGenerateInitialRoutes: (_) => [
            routeFor(
              RouteSettings(
                name: NavigationOptions.mealDetailRoute,
                arguments: MealDetailScreenArguments(
                  meal,
                  IntakeTypeEntity.snack,
                  DateTime(2026, 9, 17),
                  false,
                ),
              ),
            ),
          ],
          onGenerateRoute: routeFor,
        ),
      ),
    );
    // Not pumpAndSettle: the indeterminate LinearProgressIndicator shown
    // while hydration is in flight never settles. A few frames are enough
    // for the initial selection and the daily totals to land.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  TextEditingController quantityField(WidgetTester tester) =>
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!;

  MealEntity sheetProduct(WidgetTester tester) => tester
      .widget<MealDetailBottomSheet>(find.byType(MealDetailBottomSheet))
      .product;

  Future<void> pickUnit(WidgetTester tester, String label) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    // The open menu lists the entry once; a selected button shows it too,
    // and the menu route sits above the screen in the overlay.
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  String naLabel() =>
      '${l10nEn.notAvailableLabel} (${l10nEn.gramMilliliterUnit})';

  testWidgets(
    'Seabrook crisps: the 31.8 g serving is selected once hydration lands',
    (tester) async {
      final thin = _thin(_seabrookCrispsSearchHit);
      expect(thin.detailed, isFalse);
      expect(thin.mealUnit, isNull);
      expect(thin.scalableServingQuantity, isNull);

      await pumpMealDetail(tester, thin);

      // Before hydration the thin record has no unit at all, which is the
      // "N/A" the reporter saw.
      expect(bloc!.state.selectedUnit, UnitDropdownItem.gml.toString());
      expect(find.text(naLabel()), findsOneWidget);
      expect(find.text('31.8g'), findsNothing);

      hydration.complete(_full(_seabrookCrispsProduct));
      await tester.pumpAndSettle();

      // The hydrated record carries a scalable 31.8 g serving, so the
      // default the reporter expected is "1 serving". Before the fix the
      // re-pick ended on "N/A" beside a quantity of 1: the sheet's
      // controller listener echoed the quantity write back with the unit
      // it had last rendered, and that echo was the last event on the
      // wire.
      expect(bloc!.state.selectedUnit, UnitDropdownItem.serving.toString());
      expect(quantityField(tester).text, '1');
      expect(bloc!.state.totalQuantityConverted, '31.8');
      // 514 kcal/100 g x 31.8 g; OFF's own energy-kcal_serving is 163.
      expect(bloc!.state.totalKcal, closeTo(163, 1));
      expect(find.text('31.8g'), findsOneWidget);
      expect(find.text(naLabel()), findsNothing);
    },
  );

  testWidgets(
    'Seabrook crisps: picking the 31.8 g entry after hydration keeps it',
    (tester) async {
      await pumpMealDetail(tester, _thin(_seabrookCrispsSearchHit));
      hydration.complete(_full(_seabrookCrispsProduct));
      await tester.pumpAndSettle();
      expect(sheetProduct(tester).detailed, isTrue);

      // Opening the menu pushes a route over the screen, which re-runs its
      // didChangeDependencies. That alone used to hand the thin search hit
      // back to the sheet — no serving entry, nothing to scale by.
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      expect(sheetProduct(tester).detailed, isTrue);
      expect(sheetProduct(tester).scalableServingQuantity, 31.8);
      await tester.tap(find.text(naLabel()).last);
      await tester.pumpAndSettle();

      // The explicit N/A pick above stands in for the state the stale echo
      // used to leave behind (first test): "N/A" showing, quantity 1. The
      // `detailed` check right after the menu opened is what turns red
      // without the read-once guard; the pick below then walks the fixed
      // path end to end — the serving entry stays selected and scales the
      // amount, instead of vanishing from the button and logging 1 g.
      expect(bloc!.state.selectedUnit, UnitDropdownItem.gml.toString());
      expect(find.text(naLabel()), findsOneWidget);
      await pickUnit(tester, '31.8g');

      expect(bloc!.state.selectedUnit, UnitDropdownItem.serving.toString());
      expect(bloc!.state.totalQuantityConverted, '31.8');
      expect(sheetProduct(tester).detailed, isTrue);
      // The closed button still reads "31.8g".
      expect(find.text('31.8g'), findsOneWidget);
      expect(find.text(naLabel()), findsNothing);
    },
  );

  testWidgets(
    'Seabrook multipack: a package quantity but no serving stays on grams',
    (tester) async {
      final thin = _thin(_seabrookMultipackSearchHit);
      expect(thin.mealUnit, 'g');
      expect(thin.scalableServingQuantity, isNull);

      await pumpMealDetail(tester, thin);
      expect(bloc!.state.selectedUnit, UnitDropdownItem.g.toString());
      expect(quantityField(tester).text, '100');

      hydration.complete(_full(_seabrookMultipackProduct));
      await tester.pumpAndSettle();

      // Nothing to scale by ("6 x 25g" is a package, not a serving), so
      // the record keeps its 100 g default and offers no serving entry.
      expect(bloc!.state.selectedUnit, UnitDropdownItem.g.toString());
      expect(quantityField(tester).text, '100');
      expect(bloc!.state.totalQuantityConverted, '100.0');
      expect(find.text(l10nEn.gramUnit), findsOneWidget);
      expect(find.textContaining(l10nEn.servingLabel), findsNothing);
    },
  );
}

class _FakeGetConfigUsecase implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(true, true, false, AppThemeEntity.system);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeAddIntakeUsecase implements AddIntakeUsecase {
  @override
  Future<void> addIntake(IntakeEntity intakeEntity) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeAddTrackedDayUsecase implements AddTrackedDayUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetKcalGoalUsecase implements GetKcalGoalUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetMacroGoalUsecase implements GetMacroGoalUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetTrackedDayUsecase implements GetTrackedDayUsecase {
  @override
  Future<TrackedDayEntity?> getTrackedDay(DateTime day) async =>
      TrackedDayEntity(
        day: day,
        calorieGoal: 2200,
        caloriesTracked: 800,
        carbsGoal: 250,
        carbsTracked: 100,
        fatGoal: 70,
        fatTracked: 30,
        proteinGoal: 120,
        proteinTracked: 50,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

/// Hydration answers with whatever future the test hands it, so a test can
/// hold the full record back until the screen has rendered the thin one.
class _FakeProductsRepository implements ProductsRepository {
  final Future<MealEntity> Function() hydrated;

  _FakeProductsRepository(this.hydrated);

  @override
  Future<MealEntity> getOFFProductByBarcode(String barcode) => hydrated();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeRemoteSearchCacheDataSource implements RemoteSearchCacheDataSource {
  @override
  MealDBO? getDetailedByBarcode(String barcode) => null;

  @override
  Future<void> cache(MealDBO meal) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetIntakeUsecase implements GetIntakeUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeHomeBloc implements HomeBloc {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeDiaryBloc implements DiaryBloc {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeCalendarDayBloc implements CalendarDayBloc {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

/// The screen renders a [CachedNetworkImage] for the product photo; an
/// empty stream sends it straight to its placeholder.
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
