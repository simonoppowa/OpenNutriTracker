import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
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
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/favourite_toggle_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_title_expanded.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../helpers/fake_favourites.dart';

/// The meal detail screen paints its canvas colour behind the status bar and
/// the home indicator.
///
/// A `SafeArea` around the whole `Scaffold` shrank the page to the safe
/// rectangle, so nothing painted the insets and they showed as black bars on
/// iPhones. The page now fills the screen; the pinned app bar keeps its
/// content below the status bar and the bottom sheet keeps Add above the
/// home indicator.
void main() {
  final getIt = GetIt.instance;

  // A large iPhone with a Dynamic Island: 430 x 932 points, 59 pt status
  // bar, 34 pt home indicator. (The test font's wide glyphs overflow the
  // macro row on narrower screens.)
  const screen = Size(430, 932);
  const topInset = 59.0;
  const bottomInset = 34.0;
  const keyboardHeight = 300.0;
  const devicePixelRatio = 3.0;

  setUp(() {
    getIt.registerLazySingleton<MealDetailBloc>(
      () => MealDetailBloc(
        _FakeAddIntakeUsecase(),
        _FakeAddTrackedDayUsecase(),
        _FakeGetKcalGoalUsecase(),
        _FakeGetMacroGoalUsecase(),
        _FakeGetTrackedDayUsecase(),
        _FakeProductsRepository(),
        _FakeRemoteSearchCacheDataSource(),
      ),
    );
    getIt.registerLazySingleton<GetConfigUsecase>(_FakeGetConfigUsecase.new);
    getIt.registerLazySingleton<GetIntakeUsecase>(_FakeGetIntakeUsecase.new);
    getIt.registerLazySingleton<CacheManager>(_FakeCacheManager.new);
    final favourites = FakeFavourites();
    getIt.registerFactory<FavouriteToggleBloc>(
      () => FavouriteToggleBloc(favourites.get, favourites.toggle),
    );
    getIt.registerLazySingleton<HomeBloc>(_FakeHomeBloc.new);
    getIt.registerLazySingleton<DiaryBloc>(_FakeDiaryBloc.new);
    getIt.registerLazySingleton<CalendarDayBloc>(_FakeCalendarDayBloc.new);
  });

  tearDown(() async {
    await getIt.reset();
  });

  const meal = MealEntity(
    code: 'safe-area-test',
    name: 'Oats',
    url: null,
    mealQuantity: null,
    mealUnit: 'g',
    servingQuantity: null,
    servingUnit: 'g',
    servingSize: null,
    nutriments: MealNutrimentsEntity(
      energyKcal100: 370,
      carbohydrates100: 60,
      fat100: 7,
      proteins100: 13,
      sugars100: 1,
      saturatedFat100: 1,
      fiber100: 10,
    ),
    source: MealSourceEntity.custom,
  );

  Future<void> pumpMealDetail(
    WidgetTester tester,
    Brightness brightness,
  ) async {
    tester.view.physicalSize = screen * devicePixelRatio;
    tester.view.devicePixelRatio = devicePixelRatio;
    tester.view.padding = const FakeViewPadding(
      top: topInset * devicePixelRatio,
      bottom: bottomInset * devicePixelRatio,
    );
    tester.view.viewPadding = const FakeViewPadding(
      top: topInset * devicePixelRatio,
      bottom: bottomInset * devicePixelRatio,
    );
    addTearDown(tester.view.reset);

    Route<void> routeFor(RouteSettings settings) => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const MealDetailScreen(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<EnergyUnitProvider>(
        create: (_) => EnergyUnitProvider(),
        child: MaterialApp(
          theme: ThemeData(brightness: brightness),
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          initialRoute: NavigationOptions.mealDetailRoute,
          onGenerateInitialRoutes: (_) => [
            routeFor(
              RouteSettings(
                name: NavigationOptions.mealDetailRoute,
                arguments: MealDetailScreenArguments(
                  meal,
                  IntakeTypeEntity.breakfast,
                  DateTime(2026, 10, 25),
                  false,
                ),
              ),
            ),
          ],
          onGenerateRoute: routeFor,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final (brightness, palette) in [
    (Brightness.light, AppPalette.light),
    (Brightness.dark, AppPalette.dark),
  ]) {
    group('in ${brightness.name} theme', () {
      final mealDetailScaffold = find.descendant(
        of: find.byType(MealDetailScreen),
        matching: find.byType(Scaffold),
      );
      final bottomSheet = find.descendant(
        of: find.byType(MealDetailBottomSheet),
        matching: find.byType(BottomSheet),
      );
      final add = find.descendant(
        of: bottomSheet,
        matching: find.byIcon(Icons.add_rounded),
      );

      testWidgets('the page fills the status bar and home indicator areas', (
        tester,
      ) async {
        await pumpMealDetail(tester, brightness);

        expect(
          tester.getRect(mealDetailScaffold.first),
          Offset.zero & screen,
          reason: 'the page must cover the insets, or they show black',
        );
        expect(
          tester.widget<Scaffold>(mealDetailScaffold.first).backgroundColor,
          palette.canvas,
        );
        final appBar = find.descendant(
          of: find.byType(MealDetailScreen),
          matching: find.byType(AppBar),
        );
        expect(tester.getRect(appBar).top, 0);
        expect(tester.widget<AppBar>(appBar).backgroundColor, palette.surface);
        expect(
          tester.getRect(bottomSheet).bottom,
          screen.height,
          reason: 'the sheet surface paints behind the home indicator',
        );
      });

      testWidgets('the header and Add stay inside the safe area', (
        tester,
      ) async {
        await pumpMealDetail(tester, brightness);

        expect(
          tester.getRect(find.byIcon(Icons.edit_rounded)).top,
          greaterThanOrEqualTo(topInset),
        );
        final title = find.descendant(
          of: find.byType(MealTitleExpanded),
          matching: find.byType(RichText),
        );
        expect(tester.getRect(title.first).top, greaterThanOrEqualTo(topInset));
        expect(
          tester.getRect(add).bottom,
          lessThanOrEqualTo(screen.height - bottomInset),
        );
      });

      testWidgets('with the keyboard up, the sheet drops the home indicator '
          'gap', (tester) async {
        await pumpMealDetail(tester, brightness);
        final gapWithoutKeyboard =
            tester.getRect(bottomSheet).bottom - tester.getRect(add).bottom;

        // As on a device: the keyboard covers the home indicator, so the
        // engine reports no bottom padding while it is up.
        tester.view.viewInsets = const FakeViewPadding(
          bottom: keyboardHeight * devicePixelRatio,
        );
        tester.view.padding = const FakeViewPadding(
          top: topInset * devicePixelRatio,
        );
        await tester.pumpAndSettle();

        expect(
          tester.getRect(bottomSheet).bottom,
          screen.height - keyboardHeight,
        );
        expect(
          tester.getRect(bottomSheet).bottom - tester.getRect(add).bottom,
          gapWithoutKeyboard - bottomInset,
        );
      });
    });
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

class _FakeAddIntakeUsecase implements AddIntakeUsecase {
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
  Future<TrackedDayEntity?> getTrackedDay(DateTime day) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeProductsRepository implements ProductsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeRemoteSearchCacheDataSource implements RemoteSearchCacheDataSource {
  @override
  Future<void> touch(String barcode) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetIntakeUsecase implements GetIntakeUsecase {
  @override
  Future<List<IntakeEntity>> getBreakfastIntakeByDay(
    DateTime day, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeHomeBloc implements HomeBloc {
  @override
  void add(HomeEvent event) {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeDiaryBloc implements DiaryBloc {
  @override
  void add(DiaryEvent event) {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeCalendarDayBloc implements CalendarDayBloc {
  @override
  void add(CalendarDayEvent event) {}

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
