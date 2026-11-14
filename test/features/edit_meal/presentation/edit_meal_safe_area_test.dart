import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/favourite_meal_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/edit_meal/presentation/bloc/edit_meal_bloc.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../helpers/test_l10n.dart';

/// The Edit meal screen paints its canvas colour behind the status bar and
/// the home indicator (#819).
///
/// A `SafeArea` around the whole `Scaffold` shrank the page to the safe
/// rectangle, so nothing painted the insets and they showed as black bars on
/// iPhones. The page now fills the screen; the app bar and the body keep the
/// content itself out of the insets.
void main() {
  final getIt = GetIt.instance;

  // An iPhone with a Dynamic Island: 390 x 844 points, 47 pt status bar,
  // 34 pt home indicator.
  const screen = Size(390, 844);
  const topInset = 47.0;
  const bottomInset = 34.0;
  const devicePixelRatio = 3.0;

  setUp(() {
    getIt.registerFactory<EditMealBloc>(
      () => EditMealBloc(
        _FakeGetConfigUsecase(),
        _FakeCustomMealDataSource(),
        _FakeConfigRepository(),
        _FakeFavouriteMealRepository(),
        _FakeIntakeRepository(),
      ),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  const meal = MealEntity(
    code: 'uuid-oats',
    name: 'Oats',
    url: null,
    mealQuantity: '100',
    mealUnit: 'gml',
    servingQuantity: 100,
    servingUnit: 'gml',
    servingSize: '',
    nutriments: MealNutrimentsEntity(
      energyKcal100: 370,
      carbohydrates100: 60,
      fat100: 7,
      proteins100: 13,
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
    ),
    source: MealSourceEntity.custom,
  );

  Future<void> pumpEditor(WidgetTester tester, Brightness brightness) async {
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

    await tester.pumpWidget(
      ChangeNotifierProvider<EnergyUnitProvider>(
        create: (_) => EnergyUnitProvider(),
        child: MaterialApp(
          theme: ThemeData(brightness: brightness),
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          onGenerateInitialRoutes: (_) => [
            MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('custom meals')),
            ),
            // How the custom meal list opens the editor.
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
          // Without a route factory MaterialApp builds no Navigator at all.
          onGenerateRoute: (_) => null,
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
      final editMealScaffold = find.descendant(
        of: find.byType(EditMealScreen),
        matching: find.byType(Scaffold),
      );

      testWidgets('the canvas fills the status bar and home indicator areas', (
        tester,
      ) async {
        await pumpEditor(tester, brightness);
        expect(find.text(l10nEn.editMealLabel), findsOneWidget);

        expect(
          tester.getRect(editMealScaffold),
          Offset.zero & screen,
          reason: 'the page must cover the insets, or they show black',
        );
        expect(
          tester.widget<Scaffold>(editMealScaffold).backgroundColor,
          palette.canvas,
        );
        final appBar = find.descendant(
          of: find.byType(EditMealScreen),
          matching: find.byType(AppBar),
        );
        expect(tester.getRect(appBar).top, 0);
        expect(tester.widget<AppBar>(appBar).backgroundColor, palette.canvas);
      });

      testWidgets('the title and the form stay inside the safe area', (
        tester,
      ) async {
        await pumpEditor(tester, brightness);

        expect(
          tester.getRect(find.text(l10nEn.editMealLabel)).top,
          greaterThanOrEqualTo(topInset),
        );
        final form = find.descendant(
          of: find.byType(EditMealScreen),
          matching: find.byType(ListView),
        );
        expect(
          tester.getRect(form.first).bottom,
          lessThanOrEqualTo(screen.height - bottomInset),
        );
      });
    });
  }
}

class _FakeCustomMealDataSource implements CustomMealDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeIntakeRepository implements IntakeRepository {
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

class _FakeFavouriteMealRepository implements FavouriteMealRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}
