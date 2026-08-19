import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/core/utils/navigation_predicates.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/edit_meal/presentation/bloc/edit_meal_bloc.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../helpers/test_l10n.dart';

/// Reachability cover for the black screen after logging a recipe.
///
/// The Edit Meal save unwind names `addMealRoute`, but Edit Meal is
/// reachable on stacks that never had one. Recipes tab → recipe → Log →
/// intake type pushes `mealDetailRoute` straight onto the main screen
/// (`recipe_detail_screen.dart` `_onLogPressed`), and the meal-detail edit
/// pencil then pushes `editMealRoute` with an [EditMealScreenArguments]
/// that leaves `editOnly` at its default — the create-and-log save path
/// (`meal_detail_screen.dart`, the `meal-detail-edit` action).
///
/// So the save below runs on `[main, mealDetail, editMeal]`. With
/// `ModalRoute.withName(addMealRoute)` nothing matches, every route under
/// the new meal-detail is removed — `main` included — and the intake
/// sheet's own `popUntil(main)` then empties the navigator: a black screen
/// on a device, with the intake itself already written to the database.
///
/// This test drives the real [EditMealScreen] through its real save. The
/// two screens either side of it are stubs: pushing `editMealRoute` is
/// four unconditional lines in the pencil's `onPressed`, and standing up
/// [MealDetailScreen]'s seven-usecase bloc would not make the unwind under
/// test any more real.
void main() {
  final getIt = GetIt.instance;

  final recipe = RecipeEntity(
    id: 'a3f1c0de-0000-4000-8000-000000000001',
    name: 'Chicken curry',
    description: null,
    ingredients: const [],
    totalWeightG: 800,
    aggregatedNutrimentsPer100: const MealNutrimentsEntity(
      energyKcal100: 120,
      carbohydrates100: 10,
      fat100: 5,
      proteins100: 8,
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
      sodium100: null,
      calcium100: null,
      iron100: null,
      potassium100: null,
      magnesium100: null,
      vitaminD100: null,
      vitaminB12100: null,
    ),
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
    servingsCount: 4,
  );

  setUp(() {
    getIt.registerFactory<EditMealBloc>(
      () => EditMealBloc(
        _FakeGetConfigUsecase(),
        _FakeCustomMealDataSource(),
        _FakeConfigRepository(),
      ),
    );
    getIt.registerLazySingleton<CacheManager>(() => _FakeCacheManager());
  });

  tearDown(() async {
    await getIt.unregister<EditMealBloc>();
    await getIt.unregister<CacheManager>();
  });

  /// Pumps `[main, mealDetail]` — the stack a recipe Log leaves behind —
  /// and returns the navigator so the test can push Edit Meal onto it.
  Future<NavigatorState> pumpRecipeLogStack(WidgetTester tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    Route<void> routeFor(RouteSettings settings) {
      final builder = settings.name == NavigationOptions.editMealRoute
          ? (BuildContext _) => const EditMealScreen()
          : (BuildContext _) => Scaffold(body: Text('${settings.name}-stub'));
      return MaterialPageRoute<void>(settings: settings, builder: builder);
    }

    await tester.pumpWidget(
      ChangeNotifierProvider<EnergyUnitProvider>(
        create: (_) => EnergyUnitProvider(),
        child: MaterialApp(
          navigatorKey: navigatorKey,
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          initialRoute: NavigationOptions.mainRoute,
          onGenerateInitialRoutes: (_) => [
            routeFor(const RouteSettings(name: NavigationOptions.mainRoute)),
            routeFor(
              const RouteSettings(name: NavigationOptions.mealDetailRoute),
            ),
          ],
          onGenerateRoute: routeFor,
        ),
      ),
    );
    await tester.pumpAndSettle();

    return navigatorKey.currentState!;
  }

  test('the meal-detail edit pencil opens the create-and-log save path', () {
    // `meal_detail_screen.dart` builds its arguments positionally and never
    // passes `editOnly`, so the save runs the unwind rather than a `pop()`.
    // The two Edit Meal entry points that do pass `editOnly: true`
    // (`recipes_page.dart`, `custom_meals_tab.dart`) are unaffected.
    final args = EditMealScreenArguments(
      DateTime(2026, 8, 19),
      recipe.toMealEntity(),
      IntakeTypeEntity.dinner,
      false,
    );

    expect(args.editOnly, isFalse);
  });

  testWidgets('saving a logged recipe keeps the main screen on the stack', (
    tester,
  ) async {
    final navigator = await pumpRecipeLogStack(tester);

    // What the meal-detail edit pencil pushes, argument for argument.
    navigator.pushNamed<void>(
      NavigationOptions.editMealRoute,
      arguments: EditMealScreenArguments(
        DateTime(2026, 8, 19),
        recipe.toMealEntity(),
        IntakeTypeEntity.dinner,
        false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.editMealLabel), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, l10nEn.buttonSaveLabel));
    await tester.pumpAndSettle();

    // The save lands on a fresh meal detail either way — the regression is
    // what it leaves underneath.
    expect(
      find.text('${NavigationOptions.mealDetailRoute}-stub'),
      findsOneWidget,
    );
    expect(
      navigator.canPop(),
      isTrue,
      reason:
          'main must survive the unwind, or there is nothing to '
          'return to once the intake is logged',
    );

    // The unwind the intake sheet runs next (`meal_detail_bottom_sheet.dart`,
    // Add). Before the fix this emptied the navigator: the black screen.
    navigator.popUntil(namedRouteOrFirst(NavigationOptions.mainRoute));
    await tester.pumpAndSettle();

    expect(find.text('${NavigationOptions.mainRoute}-stub'), findsOneWidget);
  });
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
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

/// The Edit Meal header renders a [CachedNetworkImage] for non-custom
/// meals; an empty stream sends it straight to its error widget.
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
