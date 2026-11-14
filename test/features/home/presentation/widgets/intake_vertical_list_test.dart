import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/presentation/widgets/share_qr_dialog.dart';
import 'package:opennutritracker/features/home/domain/entity/shared_meal_payload.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/copy_to_meal_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_card.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_sort_type.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_profiles_usecase.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/tracked_day_lock.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/core/utils/vertical_list_popup_menu_selections.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/home/presentation/widgets/intake_vertical_list.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/test_l10n.dart';

/// What a drag between meals did, in order (#1317 review).
final _dropLog = <String>[];

/// Holds the add of a drag open, as a slow write would.
Completer<void>? _addGate;

/// What "Copy to other meal" asked the bloc to copy (#842).
final _copyCalls = <(List<IntakeEntity>, IntakeTypeEntity)>[];

/// What the next copy reports: a count, or a failure to throw.
Object _copyResult = 1;

/// Writes like the real blocs: each under the tracked-day lock.
class _FakeMealDetailBloc extends Fake implements MealDetailBloc {
  @override
  Future<void> addIntake(
    BuildContext context,
    String unit,
    String amountText,
    IntakeTypeEntity type,
    MealEntity meal,
    DateTime day,
  ) => withTrackedDayLock(() async {
    await _addGate?.future;
    _dropLog.add('add');
  });

  @override
  Future<int> copyIntakesToMeal(
    BuildContext context,
    List<IntakeEntity> intakes,
    IntakeTypeEntity target, {
    ProfileStamp? startedOn,
  }) async {
    _copyCalls.add((intakes, target));
    final result = _copyResult;
    if (result is int) return result;
    throw result;
  }
}

class _FakeHomeBloc extends Fake implements HomeBloc {
  @override
  Future<void> deleteIntakeItem(IntakeEntity intakeEntity) =>
      withTrackedDayLock(() async => _dropLog.add('delete'));

  @override
  void add(HomeEvent event) {}
}

class _FakeDiaryBloc extends Fake implements DiaryBloc {
  @override
  void add(DiaryEvent event) {}
}

class _FakeCalendarDayBloc extends Fake implements CalendarDayBloc {
  @override
  void add(CalendarDayEvent event) {}
}

/// Single-profile stub: with only one profile the "Copy to profile" menu
/// item stays hidden, so the section menu matches its pre-multi-profile
/// shape in these tests.
class _SingleProfileGetProfilesUsecase implements GetProfilesUsecase {
  static final _profile = ProfileEntity(
    id: 'p1',
    name: 'Me',
    createdAt: DateTime(2026, 1, 1),
    boxSuffix: '',
  );

  @override
  List<ProfileEntity> getProfiles() => [_profile];

  @override
  String get activeProfileId => 'p1';

  @override
  ProfileEntity? getActiveProfile() => _profile;
}

class _RecipeDataSource extends Fake implements RecipeDataSource {
  final _recipes = <String, RecipeDBO>{};

  @override
  Future<void> saveRecipe(RecipeDBO recipe) async {
    _recipes[recipe.id] = recipe;
  }

  @override
  RecipeDBO? getRecipeById(String id) => _recipes[id];
}

IntakeEntity _buildIntake({
  String id = 'test-intake',
  String name = 'Test Meal',
  required double amount,
  required double kcal100,
  required double carbs100,
  required double fat100,
  required double protein100,
}) {
  return IntakeEntity(
    id: id,
    unit: 'g',
    amount: amount,
    type: IntakeTypeEntity.breakfast,
    dateTime: DateTime(2026, 1, 1),
    meal: MealEntity(
      code: 'test-meal',
      name: name,
      url: null,
      mealQuantity: '100',
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: 'g',
      servingSize: '100 g',
      nutriments: MealNutrimentsEntity(
        energyKcal100: kcal100,
        carbohydrates100: carbs100,
        fat100: fat100,
        proteins100: protein100,
        sugars100: null,
        saturatedFat100: null,
        fiber100: null,
      ),
      source: MealSourceEntity.custom,
    ),
  );
}

Widget _wrapWithMaterial(Widget child) {
  return ChangeNotifierProvider<EnergyUnitProvider>(
    create: (_) => EnergyUnitProvider(),
    child: MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  setUpAll(() {
    final locator = GetIt.instance;
    locator.registerSingleton<RecipeRepository>(
      RecipeRepository(_RecipeDataSource()),
    );
    locator.registerFactory<MealDetailBloc>(_FakeMealDetailBloc.new);
    locator.registerFactory<HomeBloc>(_FakeHomeBloc.new);
    locator.registerFactory<DiaryBloc>(_FakeDiaryBloc.new);
    locator.registerFactory<CalendarDayBloc>(_FakeCalendarDayBloc.new);
    locator.registerFactory<GetProfilesUsecase>(
      _SingleProfileGetProfilesUsecase.new,
    );
  });

  tearDownAll(() {
    GetIt.instance.reset();
  });

  // 100 g intake of food with 200 kcal/100g, 20 g carbs/100g, 10 g fat/100g, 5 g protein/100g
  // → totals: 200 kcal, 20 g C, 10 g F, 5 g P
  final intakes = [
    _buildIntake(
      amount: 100,
      kcal100: 200,
      carbs100: 20,
      fat100: 10,
      protein100: 5,
    ),
  ];

  String headerWithMacros() =>
      '200 ${l10nEn.kcalLabel}\n'
      '20 ${l10nEn.carbsLabelShort}  '
      '10 ${l10nEn.fatLabelShort}  '
      '5 ${l10nEn.proteinLabelShort}';

  String headerKcalOnly() => '200 ${l10nEn.kcalLabel}';

  testWidgets('sharing one food exports only its logged portion', (
    tester,
  ) async {
    final selected = _buildIntake(
      id: 'selected',
      name: 'Selected food',
      amount: 60,
      kcal100: 200,
      carbs100: 20,
      fat100: 10,
      protein100: 5,
    );
    await tester.pumpWidget(
      _wrapWithMaterial(
        IntakeVerticalList(
          day: DateTime(2026, 1, 1),
          title: 'Breakfast',
          listIcon: Icons.bakery_dining_outlined,
          addMealType: AddMealType.breakfastType,
          intakeList: [intakes.single, selected],
          usesImperialUnits: false,
          onDeleteIntakeCallback: (_, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('selected')),
        matching: find.byIcon(Icons.more_vert_rounded),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share food'));
    await tester.pumpAndSettle();

    final dialog = tester.widget<ShareQrDialog>(find.byType(ShareQrDialog));
    expect(dialog.title, 'Share food');
    final shared = SharedMealPayload.fromJsonString(dialog.code);
    expect(shared.totalCount, 1);
    expect(shared.items.single.name, 'Selected food');
    expect(shared.items.single.amount, 60);
    expect(shared.items.single.unit, 'g');
    expect(shared.items.single.energyKcal100, 200);
    expect(shared.items.single.carbohydrates100, 20);
    expect(shared.items.single.fat100, 10);
    expect(shared.items.single.proteins100, 5);

    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byType(PopupMenuButton<VerticalListPopupMenuSelections>),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.shareMealLabel));
    await tester.pumpAndSettle();

    final mealDialog = tester.widget<ShareQrDialog>(find.byType(ShareQrDialog));
    expect(mealDialog.title, l10nEn.shareMealLabel);
    final wholeMeal = SharedMealPayload.fromJsonString(mealDialog.code);
    expect(wholeMeal.totalCount, 2);
    expect(wholeMeal.items.map((item) => item.name), [
      'Test Meal',
      'Selected food',
    ]);
  });

  testWidgets('sharing one recipe keeps its ingredients and logged portion', (
    tester,
  ) async {
    final recipe = RecipeEntity(
      id: 'recipe',
      name: 'Homemade soup',
      description: null,
      ingredients: [
        RecipeIngredientEntity(
          snapshotMeal: intakes.single.meal,
          amount: 100,
          unit: 'g',
          convertedAmountG: 100,
        ),
      ],
      totalWeightG: 100,
      aggregatedNutrimentsPer100: intakes.single.meal.nutriments,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      servingsCount: null,
    );
    await GetIt.instance<RecipeRepository>().saveRecipe(recipe);
    final selected = IntakeEntity(
      id: 'recipe-intake',
      unit: 'g',
      amount: 75,
      type: IntakeTypeEntity.breakfast,
      meal: recipe.toMealEntity(),
      dateTime: DateTime(2026, 1, 1),
    );
    await tester.pumpWidget(
      _wrapWithMaterial(
        IntakeVerticalList(
          day: DateTime(2026, 1, 1),
          title: 'Breakfast',
          listIcon: Icons.bakery_dining_outlined,
          addMealType: AddMealType.breakfastType,
          intakeList: [intakes.single, selected],
          usesImperialUnits: false,
          onDeleteIntakeCallback: (_, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('recipe-intake')),
        matching: find.byIcon(Icons.more_vert_rounded),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share food'));
    await tester.pumpAndSettle();

    final dialog = tester.widget<ShareQrDialog>(find.byType(ShareQrDialog));
    final shared = SharedMealPayload.fromJsonString(dialog.code);
    expect(shared.totalCount, 1);
    expect(shared.items, isEmpty);
    expect(shared.recipes.single.amount, 75);
    expect(shared.recipes.single.unit, 'g');
    final importedRecipe = shared.recipes.single.recipe.toRecipeEntity();
    expect(importedRecipe.name, 'Homemade soup');
    expect(importedRecipe.ingredients.single.snapshotMeal.name, 'Test Meal');
    expect(importedRecipe.ingredients.single.convertedAmountG, 100);
    expect(importedRecipe.aggregatedNutrimentsPer100.energyKcal100, 200);
  });

  testWidgets('passes macro sort to rows and drag feedback', (tester) async {
    await tester.pumpWidget(_wrapWithMaterial(IntakeVerticalList(
      day: DateTime(2026, 1, 1),
      title: 'Breakfast',
      listIcon: Icons.bakery_dining_outlined,
      addMealType: AddMealType.breakfastType,
      intakeList: intakes,
      usesImperialUnits: false,
      showMealMacros: false,
      sortType: DiarySortType.protein,
      onDeleteIntakeCallback: (_, _) {},
    )));
    await tester.pump();
    final card = find.byType(IntakeCard);
    expect(find.text('5.0 g protein'), findsOneWidget);
    final gesture = await tester.startGesture(tester.getCenter(card));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    expect(find.text('5.0 g protein'), findsOneWidget);
    expect(tester.widget<IntakeCard>(find.byType(IntakeCard)).sortType,
        DiarySortType.protein);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shows kcal + macro breakdown when showMealMacros is true',
    (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithMaterial(IntakeVerticalList(
        day: DateTime(2026, 1, 1),
        title: 'Breakfast',
        listIcon: Icons.bakery_dining_outlined,
        addMealType: AddMealType.breakfastType,
        intakeList: intakes,
        usesImperialUnits: false,
        showMealMacros: true,
        onDeleteIntakeCallback: (_, _) {},
      )));
      await tester.pump();

      expect(find.text(headerWithMacros()), findsOneWidget);
    },
  );

  testWidgets(
    'shows only kcal when showMealMacros is false',
    (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithMaterial(IntakeVerticalList(
        day: DateTime(2026, 1, 1),
        title: 'Breakfast',
        listIcon: Icons.bakery_dining_outlined,
        addMealType: AddMealType.breakfastType,
        intakeList: intakes,
        usesImperialUnits: false,
        showMealMacros: false,
        onDeleteIntakeCallback: (_, _) {},
      )));
      await tester.pump();

      expect(find.text(headerWithMacros()), findsNothing);
    },
  );

  testWidgets(
    'defaults to showing macro breakdown when showMealMacros is omitted',
    (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithMaterial(IntakeVerticalList(
        day: DateTime(2026, 1, 1),
        title: 'Breakfast',
        listIcon: Icons.bakery_dining_outlined,
        addMealType: AddMealType.breakfastType,
        intakeList: intakes,
        usesImperialUnits: false,
        onDeleteIntakeCallback: (_, _) {},
      )));
      await tester.pump();

      expect(find.text(headerWithMacros()), findsOneWidget);
    },
  );

  testWidgets(
    'shows no header text when intake list is empty',
    (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithMaterial(IntakeVerticalList(
        day: DateTime(2026, 1, 1),
        title: 'Breakfast',
        listIcon: Icons.bakery_dining_outlined,
        addMealType: AddMealType.breakfastType,
        intakeList: const [],
        usesImperialUnits: false,
        showMealMacros: true,
        onDeleteIntakeCallback: (_, _) {},
      )));
      await tester.pump();

      expect(find.text(headerWithMacros()), findsNothing);
      expect(find.text(headerKcalOnly()), findsNothing);
    },
  );

  // Regression: the QR-share/import options were dropped from the popup
  // menu when the macros toggle PR landed on a stale base. Lock in the
  // expected items so it can't happen again silently.
  testWidgets(
    'popup menu shows Copy/Delete/Share/Import for non-empty section',
    (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithMaterial(IntakeVerticalList(
        day: DateTime(2026, 1, 1),
        title: 'Breakfast',
        listIcon: Icons.bakery_dining_outlined,
        addMealType: AddMealType.breakfastType,
        intakeList: intakes,
        usesImperialUnits: false,
        showMealMacros: true,
        onCopyIntakeCallback: (_, _, _) {},
        onDeleteIntakeCallback: (_, _) {},
      )));
      await tester.pump();

      await tester.tap(find.byType(PopupMenuButton<VerticalListPopupMenuSelections>));
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.dialogCopyLabel), findsOneWidget);
      expect(find.text(l10nEn.deleteAllLabel), findsOneWidget);
      expect(find.text(l10nEn.shareMealLabel), findsOneWidget);
      expect(find.text(l10nEn.importMealLabel), findsOneWidget);
      expect(find.text(l10nEn.pasteCodeLabel), findsOneWidget);
    },
  );

  testWidgets(
    'popup menu shows only Import when section is empty',
    (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithMaterial(IntakeVerticalList(
        day: DateTime(2026, 1, 1),
        title: 'Breakfast',
        listIcon: Icons.bakery_dining_outlined,
        addMealType: AddMealType.breakfastType,
        intakeList: const [],
        usesImperialUnits: false,
        showMealMacros: true,
        onDeleteIntakeCallback: (_, _) {},
      )));
      await tester.pump();

      await tester.tap(find.byType(PopupMenuButton<VerticalListPopupMenuSelections>));
      await tester.pumpAndSettle();

      // Empty section: no Copy/Delete/Share — nothing to act on. Import is
      // always available so the user can scan a QR to populate the section.
      expect(find.text(l10nEn.dialogCopyLabel), findsNothing);
      expect(find.text(l10nEn.copyToOtherMealLabel), findsNothing);
      expect(find.text(l10nEn.deleteAllLabel), findsNothing);
      expect(find.text(l10nEn.shareMealLabel), findsNothing);
      expect(find.text(l10nEn.importMealLabel), findsOneWidget);
      expect(find.text(l10nEn.pasteCodeLabel), findsOneWidget);
    },
  );

  // Regression: at a phone-width header the title used to be starved of space
  // by a Spacer competing with the kcal summary for flex, so "Breakfast"
  // wrapped onto a second line ("Breakfas" / "t"). The title now takes an
  // Expanded and shrinks to fit, so it must stay on exactly one line.
  testWidgets(
    'meal title stays on a single line beside the kcal summary',
    (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithMaterial(
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 360,
            child: IntakeVerticalList(
              day: DateTime(2026, 1, 1),
              title: 'Breakfast',
              listIcon: Icons.bakery_dining_outlined,
              addMealType: AddMealType.breakfastType,
              intakeList: intakes,
              usesImperialUnits: false,
              showMealMacros: false,
              mealKcalTarget: 583,
              onDeleteIntakeCallback: (_, _) {},
            ),
          ),
        ),
      ));
      await tester.pump();

      // No RenderFlex overflow from the header competing for width.
      expect(tester.takeException(), isNull);

      final titleFinder = find.text('Breakfast');
      expect(titleFinder, findsOneWidget);
      // A single line of titleLarge (21px) renders around one line-height tall;
      // the old wrapped layout produced two lines (~double). Anything under
      // this threshold can only be a single line.
      final paragraph = tester.renderObject<RenderParagraph>(titleFinder);
      expect(paragraph.size.height, lessThan(35));
    },
  );

  testWidgets('a profile switch queued during a drag between meals waits '
      'for the delete', (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrapWithMaterial(
        IntakeVerticalList(
          day: DateTime(2026, 1, 1),
          title: 'Lunch',
          listIcon: Icons.lunch_dining_outlined,
          addMealType: AddMealType.lunchType,
          intakeList: const [],
          usesImperialUnits: false,
          onDeleteIntakeCallback: (_, _) {},
        ),
      ),
    );
    _dropLog.clear();
    _addGate = Completer<void>();
    addTearDown(() => _addGate = null);

    final target = tester.widget<DragTarget<IntakeEntity>>(
      find.byType(DragTarget<IntakeEntity>),
    );
    target.onAcceptWithDetails!(
      DragTargetDetails(data: intakes.single, offset: Offset.zero),
    );
    await tester.pump();
    // The switch takes the lock from the box swap on.
    final switched = withTrackedDayLock(() async => _dropLog.add('switch'));
    _addGate!.complete();
    await tester.pump();
    await switched;
    await tester.pump();

    expect(_dropLog, ['add', 'delete', 'switch']);
  });

  group('Copy to other meal (#842)', () {
    final lunch = [
      _buildIntake(
        id: 'rice',
        name: 'Rice',
        amount: 200,
        kcal100: 130,
        carbs100: 28,
        fat100: 0.3,
        protein100: 2.7,
      ),
      _buildIntake(
        id: 'curry',
        name: 'Curry',
        amount: 250,
        kcal100: 90,
        carbs100: 6,
        fat100: 5,
        protein100: 7,
      ),
    ];

    setUp(() {
      _copyCalls.clear();
      _copyResult = 2;
    });

    /// A lunch section as Home builds it: today, no "Copy to today", in a
    /// scrolling list.
    Widget lunchSection(List<IntakeEntity> intakes) => _wrapWithMaterial(
      ListView(
        children: [
          IntakeVerticalList(
            day: DateTime(2026, 11, 9),
            title: 'Lunch',
            listIcon: Icons.lunch_dining_outlined,
            addMealType: AddMealType.lunchType,
            intakeList: intakes,
            usesImperialUnits: false,
            onDeleteIntakeCallback: (_, _) {},
          ),
        ],
      ),
    );

    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(
        find.byType(PopupMenuButton<VerticalListPopupMenuSelections>),
      );
      await tester.pumpAndSettle();
    }

    Future<void> openPicker(WidgetTester tester) async {
      await openMenu(tester);
      await tester.tap(find.text(l10nEn.copyToOtherMealLabel));
      await tester.pumpAndSettle();
    }

    Finder bySemanticsId(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );

    testWidgets('a meal with entries on today offers it, with an id', (
      tester,
    ) async {
      await tester.pumpWidget(lunchSection(lunch));
      await openMenu(tester);

      expect(find.text(l10nEn.copyToOtherMealLabel), findsOneWidget);
      expect(bySemanticsId('intake-copy-to-other-meal'), findsOneWidget);
      // Home has no "Copy to today" for today's own meals.
      expect(find.text(l10nEn.dialogCopyLabel), findsNothing);
    });

    testWidgets('an empty meal does not offer it', (tester) async {
      await tester.pumpWidget(lunchSection(const []));
      await openMenu(tester);

      expect(find.text(l10nEn.copyToOtherMealLabel), findsNothing);
    });

    testWidgets('a past day offers it next to Copy to today', (tester) async {
      await tester.pumpWidget(
        _wrapWithMaterial(
          IntakeVerticalList(
            day: DateTime(2026, 11, 8),
            title: 'Lunch',
            listIcon: Icons.lunch_dining_outlined,
            addMealType: AddMealType.lunchType,
            intakeList: lunch,
            usesImperialUnits: false,
            onCopyIntakeCallback: (_, _, _) {},
            onDeleteIntakeCallback: (_, _) {},
          ),
        ),
      );
      await openMenu(tester);

      expect(find.text(l10nEn.dialogCopyLabel), findsOneWidget);
      expect(find.text(l10nEn.copyToOtherMealLabel), findsOneWidget);
    });

    testWidgets('the picker lists the other meals, not the source', (
      tester,
    ) async {
      await tester.pumpWidget(lunchSection(lunch));
      await openPicker(tester);

      final dialog = find.byType(CopyToMealDialog);
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(of: dialog, matching: find.text(l10nEn.lunchLabel)),
        findsNothing,
      );
      for (final (label, id) in [
        (l10nEn.breakfastLabel, 'copy-to-meal-breakfast'),
        (l10nEn.dinnerLabel, 'copy-to-meal-dinner'),
        (l10nEn.snackLabel, 'copy-to-meal-snack'),
      ]) {
        expect(
          find.descendant(of: dialog, matching: find.text(label)),
          findsOneWidget,
        );
        expect(bySemanticsId(id), findsOneWidget);
      }
      expect(bySemanticsId('copy-to-meal-lunch'), findsNothing);
    });

    testWidgets('picking Dinner copies the whole meal and says how many', (
      tester,
    ) async {
      await tester.pumpWidget(lunchSection(lunch));
      await openPicker(tester);

      await tester.tap(find.text(l10nEn.dinnerLabel));
      await tester.pumpAndSettle();

      expect(_copyCalls, hasLength(1));
      final (copied, target) = _copyCalls.single;
      expect(copied.map((i) => i.id), ['rice', 'curry']);
      expect(target, IntakeTypeEntity.dinner);
      expect(
        find.text(l10nEn.copiedToMealSnackbar(2, l10nEn.dinnerLabel)),
        findsOneWidget,
      );
      expect(find.text('Copied 2 items to Dinner'), findsOneWidget);
    });

    testWidgets('one copied item reads in the singular', (tester) async {
      _copyResult = 1;
      await tester.pumpWidget(lunchSection([lunch.first]));
      await openPicker(tester);

      await tester.tap(find.text(l10nEn.snackLabel));
      await tester.pumpAndSettle();

      expect(find.text('Copied 1 item to Snack'), findsOneWidget);
    });

    testWidgets('cancelling the picker copies nothing', (tester) async {
      await tester.pumpWidget(lunchSection(lunch));
      await openPicker(tester);

      await tester.tap(find.text(l10nEn.dialogCancelLabel));
      await tester.pumpAndSettle();

      expect(_copyCalls, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a copy a profile switch abandoned shows no confirmation', (
      tester,
    ) async {
      _copyResult = 0;
      await tester.pumpWidget(lunchSection(lunch));
      await openPicker(tester);

      await tester.tap(find.text(l10nEn.dinnerLabel));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a copy that stops partway says so', (tester) async {
      _copyResult = CopyIntakesToMealException(
        1,
        StateError('disk full'),
        StackTrace.empty,
      );
      await tester.pumpWidget(lunchSection(lunch));
      await openPicker(tester);

      await tester.tap(find.text(l10nEn.dinnerLabel));
      await tester.pumpAndSettle();

      expect(
        find.text(l10nEn.copyToMealFailedSnackbar(l10nEn.dinnerLabel)),
        findsOneWidget,
      );
    });

    testWidgets('picker options fit a narrow screen at a large font', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(lunchSection(lunch));
      expect(tester.takeException(), isNull, reason: 'section');
      await openMenu(tester);
      expect(tester.takeException(), isNull, reason: 'menu');
      await tester.tap(find.text(l10nEn.copyToOtherMealLabel));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'dialog');
    });
  });
}
