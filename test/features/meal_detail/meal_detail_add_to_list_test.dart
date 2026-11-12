import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/log_tray.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../helpers/test_l10n.dart';

class _FakeAddIntakeUsecase extends Fake implements AddIntakeUsecase {}

class _FakeAddTrackedDayUsecase extends Fake implements AddTrackedDayUsecase {}

class _FakeGetKcalGoalUsecase extends Fake implements GetKcalGoalUsecase {}

class _FakeGetMacroGoalUsecase extends Fake implements GetMacroGoalUsecase {}

class _FakeGetTrackedDayUsecase extends Fake implements GetTrackedDayUsecase {}

class _FakeProductsRepository extends Fake implements ProductsRepository {}

class _FakeRemoteSearchCacheDataSource extends Fake
    implements RemoteSearchCacheDataSource {}

/// Nothing logged yet, so the duplicate check lets every tap through.
class _NothingLoggedGetIntakeUsecase extends Fake implements GetIntakeUsecase {
  @override
  Future<List<IntakeEntity>> getBreakfastIntakeByDay(
    DateTime day, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async => [];
}

/// Throws if asked: editing a row on the list is not a second helping, so
/// the duplicate check must not run.
class _ThrowingGetIntakeUsecase extends Fake implements GetIntakeUsecase {}

class _FakeHomeBloc extends Fake implements HomeBloc {
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

/// Counts the intakes it is asked to store, and holds each save open
/// until [save] completes, as a write waiting for the tracked-day lock.
class _CountingMealDetailBloc extends MealDetailBloc {
  _CountingMealDetailBloc()
    : super(
        _FakeAddIntakeUsecase(),
        _FakeAddTrackedDayUsecase(),
        _FakeGetKcalGoalUsecase(),
        _FakeGetMacroGoalUsecase(),
        _FakeGetTrackedDayUsecase(),
        _FakeProductsRepository(),
        _FakeRemoteSearchCacheDataSource(),
      );

  var saves = 0;

  @override
  Future<void> addIntake(
    BuildContext context,
    String unit,
    String amountText,
    IntakeTypeEntity type,
    MealEntity meal,
    DateTime day,
  ) {
    saves++;
    return Future.value();
  }
}

final _toast = MealEntity(
  code: 'toast',
  name: 'Toast',
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: 'g',
  servingSize: null,
  nutriments: const MealNutrimentsEntity(
    energyKcal100: 200,
    carbohydrates100: 40,
    fat100: 2,
    proteins100: 6,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  source: MealSourceEntity.custom,
);

const _otherMeal = MealEntity(
  code: 'jam',
  name: 'Jam',
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: 'g',
  servingSize: null,
  nutriments: MealNutrimentsEntity(
    energyKcal100: 250,
    carbohydrates100: 60,
    fat100: 0,
    proteins100: 0,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  source: MealSourceEntity.custom,
);

/// #1317 review: the save can wait for the tracked-day lock with the sheet
/// still open, so Add has to take one tap per meal.
void main() {
  setUp(() {
    GetIt.instance
      ..registerFactory<GetIntakeUsecase>(_NothingLoggedGetIntakeUsecase.new)
      ..registerFactory<HomeBloc>(_FakeHomeBloc.new)
      ..registerFactory<DiaryBloc>(_FakeDiaryBloc.new)
      ..registerFactory<CalendarDayBloc>(_FakeCalendarDayBloc.new);
  });

  tearDown(() => GetIt.instance.reset());

  Future<(_CountingMealDetailBloc, LogTray)> pumpSheet(
    WidgetTester tester, {
    List<LogTrayItem> onList = const [],
  }) async {
    final bloc = _CountingMealDetailBloc();
    addTearDown(bloc.close);
    final tray = LogTray()..addAll(onList);
    addTearDown(tray.dispose);
    bloc.add(
      UpdateKcalEvent(meal: _toast, totalQuantity: '150', selectedUnit: 'g'),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: MealDetailBottomSheet(
              product: _toast,
              day: DateTime(2026, 10, 5),
              intakeTypeEntity: IntakeTypeEntity.breakfast,
              quantityTextController: TextEditingController(text: '150'),
              mealDetailBloc: bloc,
              selectedUnit: 'g',
              onQuantityOrUnitChanged: (_, _) {},
              logTray: tray,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (bloc, tray);
  }

  void expectToastOnList(LogTray tray) {
    final item = tray.items.last;
    expect(item.meal.name, 'Toast');
    expect(item.unit, 'g');
    expect(item.amount, 150);
    expect(item.amountLabel, '150 ${l10nEn.gramUnit}');
    expect(item.kcal, 300);
    expect(item.quantity, 150);
    expect(item.selectedUnit, 'g');
  }

  Text buttonLabel(WidgetTester tester, String identifier) =>
      tester.widget<Text>(
        find.descendant(
          of: find.bySemanticsIdentifier(identifier),
          matching: find.byType(Text),
        ),
      );

  group('opened from the add-food screen (#1520)', () {
    testWidgets('with nothing on the list, Add logs at once', (tester) async {
      final (bloc, tray) = await pumpSheet(tester);

      expect(buttonLabel(tester, 'meal-detail-add').data, l10nEn.addLabel);
      await tester.tap(find.bySemanticsIdentifier('meal-detail-add'));
      await tester.pumpAndSettle();

      // Straight to the diary, as before the list existed: no second tap
      // on "Log 1 item".
      expect(bloc.saves, 1);
      expect(tray.isEmpty, isTrue);
    });

    testWidgets('with nothing on the list, Add to list starts one', (
      tester,
    ) async {
      final (bloc, tray) = await pumpSheet(tester);

      final addToList = find.bySemanticsIdentifier('meal-detail-add-to-list');
      expect(
        buttonLabel(tester, 'meal-detail-add-to-list').data,
        l10nEn.addToListLabel,
      );
      await tester.tap(addToList);
      await tester.pumpAndSettle();

      // Nothing reached the diary; the list holds what would have.
      expect(bloc.saves, 0);
      expect(tray.length, 1);
      expectToastOnList(tray);
    });

    testWidgets(
      'a + that starts fetching while the sheet is open turns Add into Add '
      'to list',
      (tester) async {
        final (bloc, tray) = await pumpSheet(tester);
        expect(buttonLabel(tester, 'meal-detail-add').data, l10nEn.addLabel);

        // A + on the add-food screen behind the sheet, still fetching its
        // food. Logging at once now would leave before it arrives.
        tray.beginPending();
        await tester.pump();
        expect(
          buttonLabel(tester, 'meal-detail-add').data,
          l10nEn.addToListLabel,
        );
        await tester.tap(find.bySemanticsIdentifier('meal-detail-add'));
        await tester.pumpAndSettle();

        expect(bloc.saves, 0);
        expect(tray.length, 1);
        expectToastOnList(tray);
        tray.endPending();
      },
    );

    testWidgets('once the list has items, the button adds to it', (
      tester,
    ) async {
      final (bloc, tray) = await pumpSheet(
        tester,
        onList: [
          LogTrayItem(meal: _toast, unit: 'g', amount: 50, amountLabel: '50 g'),
        ],
      );

      expect(
        buttonLabel(tester, 'meal-detail-add').data,
        l10nEn.addToListLabel,
      );
      // One way on, not two buttons that do the same thing.
      expect(
        find.bySemanticsIdentifier('meal-detail-add-to-list'),
        findsNothing,
      );
      await tester.tap(find.bySemanticsIdentifier('meal-detail-add'));
      await tester.pumpAndSettle();

      // Logging this one alone would leave the list behind on a screen
      // the user has just left.
      expect(bloc.saves, 0);
      expect(tray.length, 2);
      expectToastOnList(tray);
    });
  });

  Future<void> pumpEditing(
    WidgetTester tester, {
    required _CountingMealDetailBloc bloc,
    required LogTray tray,
    required LogTrayItem editing,
    required String quantity,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: MealDetailBottomSheet(
              product: _toast,
              day: DateTime(2026, 10, 5),
              intakeTypeEntity: IntakeTypeEntity.breakfast,
              quantityTextController: TextEditingController(text: quantity),
              mealDetailBloc: bloc,
              selectedUnit: 'g',
              onQuantityOrUnitChanged: (_, _) {},
              logTray: tray,
              editingTrayItem: editing,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opened from a row on the list, Save changes that row in place', (
    tester,
  ) async {
    GetIt.instance
      ..unregister<GetIntakeUsecase>()
      ..registerFactory<GetIntakeUsecase>(_ThrowingGetIntakeUsecase.new);
    final bloc = _CountingMealDetailBloc();
    addTearDown(bloc.close);
    final tray = LogTray();
    addTearDown(tray.dispose);
    const before = LogTrayItem(
      meal: _otherMeal,
      unit: 'g',
      amount: 50,
      amountLabel: '50 g',
    );
    final editing = LogTrayItem(
      meal: _toast,
      unit: 'g',
      amount: 100,
      amountLabel: '100 g',
      quantity: 100,
      selectedUnit: 'g',
    );
    const after = LogTrayItem(
      meal: _otherMeal,
      unit: 'g',
      amount: 70,
      amountLabel: '70 g',
    );
    tray.addAll([before, editing, after]);
    bloc.add(
      UpdateKcalEvent(meal: _toast, totalQuantity: '250', selectedUnit: 'g'),
    );
    await pumpEditing(
      tester,
      bloc: bloc,
      tray: tray,
      editing: editing,
      quantity: '250',
    );

    expect(find.text(l10nEn.buttonSaveLabel), findsOneWidget);
    expect(find.text(l10nEn.addToListLabel), findsNothing);
    await tester.tap(find.bySemanticsIdentifier('meal-detail-add'));
    await tester.pumpAndSettle();

    expect(bloc.saves, 0);
    expect(tray.length, 3);
    expect(identical(tray.items[0], before), isTrue);
    expect(identical(tray.items[2], after), isTrue);
    final changed = tray.items[1];
    expect(changed.meal.name, 'Toast');
    expect(changed.amount, 250);
    expect(changed.quantity, 250);
    expect(changed.selectedUnit, 'g');
    expect(changed.amountLabel, '250 ${l10nEn.gramUnit}');
    expect(changed.kcal, 500);
    expect(find.text(l10nEn.logTrayAddedLabel), findsNothing);
  });

  testWidgets('a row taken off the list meanwhile is added back, not lost', (
    tester,
  ) async {
    final bloc = _CountingMealDetailBloc();
    addTearDown(bloc.close);
    final tray = LogTray();
    addTearDown(tray.dispose);
    final editing = LogTrayItem(
      meal: _toast,
      unit: 'g',
      amount: 100,
      amountLabel: '100 g',
      quantity: 100,
      selectedUnit: 'g',
    );
    bloc.add(
      UpdateKcalEvent(meal: _toast, totalQuantity: '80', selectedUnit: 'g'),
    );
    await pumpEditing(
      tester,
      bloc: bloc,
      tray: tray,
      editing: editing,
      quantity: '80',
    );

    await tester.tap(find.bySemanticsIdentifier('meal-detail-add'));
    await tester.pumpAndSettle();

    expect(tray.items.single.amount, 80);
  });

  testWidgets('a row whose food lacks a value can still change its amount', (
    tester,
  ) async {
    // The review screen accepts a food with a macro missing; once it is on
    // the list its amount must stay changeable, warning and all.
    final noProtein = MealEntity(
      code: 'no-protein',
      name: 'Mystery bar',
      url: null,
      mealQuantity: null,
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: 'g',
      servingSize: null,
      nutriments: const MealNutrimentsEntity(
        energyKcal100: 400,
        carbohydrates100: 50,
        fat100: 20,
        proteins100: null,
        sugars100: null,
        saturatedFat100: null,
        fiber100: null,
      ),
      source: MealSourceEntity.custom,
    );
    final bloc = _CountingMealDetailBloc();
    addTearDown(bloc.close);
    final tray = LogTray();
    addTearDown(tray.dispose);
    final editing = LogTrayItem(
      meal: noProtein,
      unit: 'g',
      amount: 50,
      amountLabel: '50 g',
      quantity: 50,
      selectedUnit: 'g',
    );
    tray.add(editing);
    bloc.add(
      UpdateKcalEvent(meal: noProtein, totalQuantity: '80', selectedUnit: 'g'),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: MealDetailBottomSheet(
              product: noProtein,
              day: DateTime(2026, 10, 5),
              intakeTypeEntity: IntakeTypeEntity.breakfast,
              quantityTextController: TextEditingController(text: '80'),
              mealDetailBloc: bloc,
              selectedUnit: 'g',
              onQuantityOrUnitChanged: (_, _) {},
              logTray: tray,
              editingTrayItem: editing,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
    expect(
      find.textContaining(l10nEn.missingProductInfoPer100g),
      findsOneWidget,
    );
    await tester.tap(find.bySemanticsIdentifier('meal-detail-add'));
    await tester.pumpAndSettle();

    expect(bloc.saves, 0);
    expect(tray.items.single.amount, 80);
    expect(identical(tray.items.single, editing), isFalse);
  });

  test('a row to edit without its list is a programming error', () {
    final row = LogTrayItem(
      meal: _toast,
      unit: 'g',
      amount: 100,
      amountLabel: '100 g',
      quantity: 100,
      selectedUnit: 'g',
    );
    expect(
      () => MealDetailBottomSheet(
        product: _toast,
        day: DateTime(2026, 10, 5),
        intakeTypeEntity: IntakeTypeEntity.breakfast,
        quantityTextController: TextEditingController(),
        mealDetailBloc: _CountingMealDetailBloc(),
        selectedUnit: 'g',
        onQuantityOrUnitChanged: (_, _) {},
        editingTrayItem: row,
      ),
      throwsAssertionError,
    );
  });

  testWidgets('an invalid amount leaves the row as it was', (tester) async {
    GetIt.instance
      ..unregister<GetIntakeUsecase>()
      ..registerFactory<GetIntakeUsecase>(_ThrowingGetIntakeUsecase.new);
    final bloc = _CountingMealDetailBloc();
    addTearDown(bloc.close);
    final tray = LogTray();
    addTearDown(tray.dispose);
    final editing = LogTrayItem(
      meal: _toast,
      unit: 'g',
      amount: 100,
      amountLabel: '100 g',
      quantity: 100,
      selectedUnit: 'g',
    );
    tray.add(editing);
    await pumpEditing(
      tester,
      bloc: bloc,
      tray: tray,
      editing: editing,
      quantity: '0',
    );

    await tester.tap(find.bySemanticsIdentifier('meal-detail-add'));
    await tester.pumpAndSettle();

    expect(identical(tray.items.single, editing), isTrue);
  });
}
