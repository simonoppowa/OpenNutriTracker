import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_screen.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/add_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/favourite_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/food_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/products_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recent_meal_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../helpers/fake_favourites.dart';
import '../../../helpers/test_l10n.dart';

class _FakeGetConfigUsecase implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(true, true, false, AppThemeEntity.system);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

/// Nothing logged yet — the case #1307 is about.
class _NoRecentIntake implements GetIntakeUsecase {
  @override
  Future<List<IntakeEntity>> getRecentIntake() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

/// The Favourites source never reaches the remote search.
class _UnusedSearch implements SearchProductsUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

MealEntity _meal(String code, String name) => MealEntity(
  code: code,
  name: name,
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: null,
  servingSize: null,
  nutriments: MealNutrimentsEntity.empty(),
  source: MealSourceEntity.custom,
);

Widget _app() => ChangeNotifierProvider<EnergyUnitProvider>(
  create: (_) => EnergyUnitProvider(usesKilojoules: false),
  child: MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    onGenerateRoute: (settings) => MaterialPageRoute<void>(
      settings: RouteSettings(
        name: settings.name,
        arguments: AddMealScreenArguments(
          AddMealType.lunchType,
          DateTime(2026, 10, 4),
        ),
      ),
      builder: (_) => const AddMealScreen(),
    ),
  ),
);

void main() {
  final getIt = GetIt.instance;
  late FakeFavourites favourites;

  setUp(() {
    favourites = FakeFavourites();
    final config = _FakeGetConfigUsecase();
    getIt
      ..registerFactory<AddMealBloc>(() => AddMealBloc(config))
      ..registerFactory<ProductsBloc>(
        () => ProductsBloc(_UnusedSearch(), config),
      )
      ..registerFactory<FoodBloc>(() => FoodBloc(_UnusedSearch(), config))
      ..registerFactory<RecentMealBloc>(
        () => RecentMealBloc(_NoRecentIntake(), config),
      )
      ..registerFactory<FavouriteMealBloc>(
        () => FavouriteMealBloc(favourites.get, config),
      );
  });

  tearDown(() async {
    await getIt.reset();
    await favourites.dispose();
  });

  Future<void> openFavourites(WidgetTester tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.favouritesLabel));
    await tester.pumpAndSettle();
  }

  testWidgets('lists favourites that were never logged', (tester) async {
    favourites
      ..add(_meal('lunch', 'Packed lunch'))
      ..add(_meal('oats', 'Overnight oats'));

    await openFavourites(tester);

    expect(
      find.textContaining('Packed lunch', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Overnight oats', findRichText: true),
      findsOneWidget,
    );
    // Recently is empty in this setup, so these can only come from the
    // Favourites list.
    expect(find.text(l10nEn.noMealsRecentlyAddedLabel), findsNothing);
  });

  testWidgets('shows how to add one while the list is empty', (tester) async {
    await openFavourites(tester);

    expect(find.text(l10nEn.favouritesEmptyTitle), findsOneWidget);
    expect(find.text(l10nEn.favouritesEmptySubtitle), findsOneWidget);
  });

  testWidgets('typing filters the list and stays on Favourites', (
    tester,
  ) async {
    favourites
      ..add(_meal('lunch', 'Packed lunch'))
      ..add(_meal('oats', 'Overnight oats'));
    await openFavourites(tester);

    await tester.enterText(find.byType(TextField), 'oats');
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Overnight oats', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Packed lunch', findRichText: true),
      findsNothing,
    );
    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, l10nEn.favouritesLabel),
    );
    expect(chip.selected, isTrue);

    // Clearing the field goes back to the whole list, not to Recently.
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Packed lunch', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Overnight oats', findRichText: true),
      findsOneWidget,
    );
  });
}
