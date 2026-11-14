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
import 'package:opennutritracker/core/domain/usecase/hide_recent_meal_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_screen.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/add_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/favourite_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/favourite_toggle_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/food_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/products_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recent_meal_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../helpers/fake_favourites.dart';
import '../../../helpers/test_l10n.dart';

/// #1198: a long press on a Recently row offers to take the food off the
/// list; confirming removes the row and nothing else.

class _FakeGetIntakeUsecase implements GetIntakeUsecase {
  final List<IntakeEntity> recent;

  _FakeGetIntakeUsecase(this.recent);

  @override
  Future<List<IntakeEntity>> getRecentIntake() async => List.of(recent);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

/// Hides by dropping the food's rows from [_FakeGetIntakeUsecase.recent],
/// or fails when [fails] is set.
class _FakeHide implements HideRecentMealUsecase {
  final _FakeGetIntakeUsecase intakes;
  final List<MealEntity> hidden = [];
  bool fails = false;

  _FakeHide(this.intakes);

  @override
  Future<void> hide(MealEntity meal) async {
    if (fails) throw StateError('disk full');
    hidden.add(meal);
    intakes.recent.removeWhere((intake) => intake.meal.code == meal.code);
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

class _NoSearch implements SearchProductsUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

IntakeEntity _intake(String code, String name) => IntakeEntity(
  id: code,
  unit: 'g',
  amount: 100,
  type: IntakeTypeEntity.lunch,
  meal: MealEntity(
    code: code,
    name: name,
    url: null,
    mealQuantity: null,
    mealUnit: 'g',
    servingQuantity: null,
    servingUnit: 'g',
    servingSize: null,
    nutriments: MealNutrimentsEntity.empty(),
    source: MealSourceEntity.custom,
  ),
  dateTime: DateTime(2026, 11, 1),
);

final getIt = GetIt.instance;

late _FakeGetIntakeUsecase _intakes;
late _FakeHide _hide;
FakeFavourites? _favourites;

Future<void> _register(List<IntakeEntity> recent) async {
  await getIt.reset();
  _intakes = _FakeGetIntakeUsecase(recent);
  _hide = _FakeHide(_intakes);
  final config = _FakeGetConfigUsecase();
  final search = _NoSearch();
  getIt.registerFactory<AddMealBloc>(() => AddMealBloc(config));
  getIt.registerFactory<ProductsBloc>(() => ProductsBloc(search, config));
  getIt.registerFactory<FoodBloc>(() => FoodBloc(search, config));
  getIt.registerFactory<RecentMealBloc>(() => RecentMealBloc(_intakes, config));
  getIt.registerSingleton<HideRecentMealUsecase>(_hide);
  await _favourites?.dispose();
  final favourites = _favourites = FakeFavourites();
  getIt.registerFactory<FavouriteMealBloc>(
    () => FavouriteMealBloc(favourites.get, config),
  );
  getIt.registerFactory<FavouriteToggleBloc>(
    () => FavouriteToggleBloc(favourites.get, favourites.toggle),
  );
}

Widget _app() => MaterialApp(
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
        DateTime(2026, 11, 1),
      ),
    ),
    builder: (_) => const AddMealScreen(),
  ),
);

Finder _withIdentifier(String identifier) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.identifier == identifier,
);

/// A row's title is rich text: the name, then the brand.
Finder _row(String name) => find.textContaining(name, findRichText: true);

Future<void> _openRecent(WidgetTester tester) async {
  await tester.pumpWidget(_app());
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10nEn.recentlyAddedLabel));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() async => getIt.reset());

  testWidgets('confirming removes the row and only that row', (tester) async {
    await _register([_intake('q2', 'Snack'), _intake('q1', 'Snack')]);
    await _openRecent(tester);
    expect(_row('Snack'), findsNWidgets(2));

    await tester.longPress(_row('Snack').first);
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.recentRemoveDialogTitle), findsOneWidget);
    await tester.tap(_withIdentifier('recent-remove-confirm'));
    await tester.pumpAndSettle();

    expect(_hide.hidden.map((m) => m.code), ['q2']);
    expect(_row('Snack'), findsOneWidget);
  });

  testWidgets('cancelling keeps the row', (tester) async {
    await _register([_intake('a', 'Apple')]);
    await _openRecent(tester);

    await tester.longPress(_row('Apple'));
    await tester.pumpAndSettle();
    await tester.tap(_withIdentifier('recent-remove-cancel'));
    await tester.pumpAndSettle();

    expect(_hide.hidden, isEmpty);
    expect(_row('Apple'), findsOneWidget);
  });

  testWidgets('removing the last row shows the empty hint', (tester) async {
    await _register([_intake('a', 'Apple')]);
    await _openRecent(tester);

    await tester.longPress(_row('Apple'));
    await tester.pumpAndSettle();
    await tester.tap(_withIdentifier('recent-remove-confirm'));
    await tester.pumpAndSettle();

    expect(_row('Apple'), findsNothing);
    expect(find.text(l10nEn.noMealsRecentlyAddedLabel), findsOneWidget);
  });

  testWidgets('a failed removal keeps the row and says so', (tester) async {
    await _register([_intake('a', 'Apple')]);
    _hide.fails = true;
    await _openRecent(tester);

    await tester.longPress(_row('Apple'));
    await tester.pumpAndSettle();
    await tester.tap(_withIdentifier('recent-remove-confirm'));
    await tester.pumpAndSettle();

    expect(_row('Apple'), findsOneWidget);
    expect(find.text(l10nEn.recentRemoveFailedLabel), findsOneWidget);
  });
}
