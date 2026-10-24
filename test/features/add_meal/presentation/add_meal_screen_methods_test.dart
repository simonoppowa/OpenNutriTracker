import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_screen.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/add_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/favourite_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/favourite_toggle_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/food_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/products_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recent_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/screens/bulk_add_screen.dart';
import 'package:opennutritracker/features/scanner/scanner_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../helpers/fake_favourites.dart';
import '../../../helpers/test_l10n.dart';

class _FakeGetIntakeUsecase implements GetIntakeUsecase {
  @override
  Future<List<IntakeEntity>> getRecentIntake() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetConfigUsecase implements GetConfigUsecase {
  final bool imperial;

  _FakeGetConfigUsecase({this.imperial = false});

  @override
  Future<ConfigEntity> getConfig() async => ConfigEntity(
    true,
    true,
    false,
    AppThemeEntity.system,
    usesImperialFoodUnits: imperial,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeSearch implements SearchProductsUseCase {
  @override
  Future<SearchProductsResult> searchOFFProductsByString(
    String searchString, {
    bool skipRemote = false,
  }) async => const SearchProductsResult(
    meals: <MealEntity>[],
    remoteSourceEmpty: true,
  );

  @override
  Future<SearchProductsResult> searchFDCFoodByString(
    String searchString, {
    bool skipRemote = false,
    bool forResolution = false,
  }) async => const SearchProductsResult(
    meals: <MealEntity>[],
    remoteSourceEmpty: true,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

final getIt = GetIt.instance;
FakeFavourites? _favourites;

Future<void> _register({bool imperial = false}) async {
  await getIt.reset();
  final config = _FakeGetConfigUsecase(imperial: imperial);
  final search = _FakeSearch();
  getIt.registerFactory<AddMealBloc>(() => AddMealBloc(config));
  getIt.registerFactory<ProductsBloc>(() => ProductsBloc(search, config));
  getIt.registerFactory<FoodBloc>(() => FoodBloc(search, config));
  getIt.registerFactory<RecentMealBloc>(
    () => RecentMealBloc(_FakeGetIntakeUsecase(), config),
  );
  await _favourites?.dispose();
  final favourites = _favourites = FakeFavourites();
  getIt.registerFactory<FavouriteMealBloc>(
    () => FavouriteMealBloc(favourites.get, config),
  );
  getIt.registerFactory<FavouriteToggleBloc>(
    () => FavouriteToggleBloc(favourites.get, favourites.toggle),
  );
}

/// The add-food screen at the root, and a stub for every route it pushes
/// that records what it was asked for.
Widget _app(List<RouteSettings> pushed) => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: S.supportedLocales,
  onGenerateRoute: (settings) {
    if (settings.name == Navigator.defaultRouteName) {
      return MaterialPageRoute<void>(
        settings: RouteSettings(
          name: settings.name,
          arguments: AddMealScreenArguments(
            AddMealType.breakfastType,
            DateTime(2026, 10, 18),
          ),
        ),
        builder: (_) => const AddMealScreen(),
      );
    }
    pushed.add(settings);
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const Scaffold(body: SizedBox()),
    );
  },
);

void main() {
  testWidgets('the three entry methods sit under the search field', (
    tester,
  ) async {
    await _register();
    await tester.pumpWidget(_app([]));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsIdentifier('add-meal-method-barcode'),
      findsOneWidget,
    );
    expect(find.bySemanticsIdentifier('add-meal-method-photo'), findsOneWidget);
    expect(
      find.bySemanticsIdentifier('add-meal-method-describe'),
      findsOneWidget,
    );
    expect(find.text(l10nEn.addMealSnapMealLabel), findsOneWidget);
    // The barcode moved from the field's suffix to its own tile, and the
    // second screen's app-bar icon is gone: both now start from here.
    expect(find.bySemanticsIdentifier('meal-search-barcode'), findsNothing);
    expect(find.bySemanticsIdentifier('add-meal-bulk-add'), findsNothing);
  });

  testWidgets('Barcode opens the scanner for this meal', (tester) async {
    await _register();
    final pushed = <RouteSettings>[];
    await tester.pumpWidget(_app(pushed));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsIdentifier('add-meal-method-barcode'));
    await tester.pumpAndSettle();

    expect(pushed.single.name, NavigationOptions.scannerRoute);
    expect(
      (pushed.single.arguments as ScannerScreenArguments).intakeTypeEntity,
      IntakeTypeEntity.breakfast,
    );
  });

  testWidgets('Describe opens a panel, and Find foods takes the text along', (
    tester,
  ) async {
    await _register(imperial: true);
    final pushed = <RouteSettings>[];
    await tester.pumpWidget(_app(pushed));
    await tester.pumpAndSettle();

    expect(find.bySemanticsIdentifier('add-meal-describe-input'), findsNothing);
    await tester.tap(find.bySemanticsIdentifier('add-meal-method-describe'));
    await tester.pumpAndSettle();

    // Nothing to find yet, so nothing to tap.
    final submit = find.descendant(
      of: find.bySemanticsIdentifier('add-meal-describe-submit'),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    expect(tester.widget<ButtonStyleButton>(submit).onPressed, isNull);

    await tester.enterText(
      find.descendant(
        of: find.bySemanticsIdentifier('add-meal-describe-input'),
        matching: find.byType(TextField),
      ),
      '200g broccoli and 3 eggs',
    );
    await tester.pump();
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(pushed.single.name, NavigationOptions.bulkAddRoute);
    final args = pushed.single.arguments as BulkAddScreenArguments;
    expect(args.initialText, '200g broccoli and 3 eggs');
    expect(args.startWithPhoto, isFalse);
    expect(args.intakeTypeEntity, IntakeTypeEntity.breakfast);
    expect(args.usesImperialUnits, isTrue);
  });

  testWidgets('Snap meal goes to the review screen ready for a photo', (
    tester,
  ) async {
    await _register();
    final pushed = <RouteSettings>[];
    await tester.pumpWidget(_app(pushed));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsIdentifier('add-meal-method-photo'));
    await tester.pumpAndSettle();

    expect(pushed.single.name, NavigationOptions.bulkAddRoute);
    final args = pushed.single.arguments as BulkAddScreenArguments;
    expect(args.startWithPhoto, isTrue);
    expect(args.initialText, isNull);
  });

  // Portrait and the landscape case #165 was about: the tiles and the open
  // panel scroll inside their own share rather than push the results off.
  for (final size in const [Size(360, 780), Size(780, 360)]) {
    testWidgets('the screen fits with Describe open at $size', (tester) async {
      await _register();
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app([]));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('add-meal-method-describe'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.bySemanticsIdentifier('add-meal-describe-input'),
        findsOneWidget,
      );
    });
  }
}
