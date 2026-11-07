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
}
