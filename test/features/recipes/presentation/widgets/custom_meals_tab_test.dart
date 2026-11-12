import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/recipes/presentation/widgets/custom_meals_tab.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/custom_meals_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class _LoadedBloc extends Fake implements CustomMealsBloc {
  @override
  final CustomMealsState state;

  _LoadedBloc(this.state);

  @override
  Stream<CustomMealsState> get stream => const Stream.empty();
}

void main() {
  // Edge-to-edge draws the navigation bar over the list; its end clears
  // the bar so the last meal can be scrolled into reach.
  testWidgets('the list ends above the navigation bar', (tester) async {
    // As a device reports a 48 dp bar, at 3x.
    tester.view.padding = const FakeViewPadding(bottom: 144);
    tester.view.viewPadding = const FakeViewPadding(bottom: 144);
    addTearDown(tester.view.reset);
    final navigationBar = 144 / tester.view.devicePixelRatio;

    final meals = [
      for (var i = 0; i < 3; i++)
        MealEntity(
          code: 'meal-$i',
          name: 'Meal $i',
          url: null,
          mealQuantity: null,
          mealUnit: 'g',
          servingQuantity: null,
          servingUnit: 'g',
          servingSize: null,
          nutriments: MealNutrimentsEntity.empty(),
          source: MealSourceEntity.custom,
        ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          appBar: AppBar(),
          body: BlocProvider<CustomMealsBloc>.value(
            value: _LoadedBloc(CustomMealsLoadedState(meals: meals)),
            child: const CustomMealsTab(usesImperialUnits: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final padding = tester.widget<ListView>(find.byType(ListView)).padding!;
    expect(
      padding.resolve(TextDirection.ltr).bottom,
      greaterThanOrEqualTo(navigationBar),
    );
  });
}
