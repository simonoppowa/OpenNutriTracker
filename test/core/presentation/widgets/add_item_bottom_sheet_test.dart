import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/presentation/widgets/add_item_bottom_sheet.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/favourite_toggle_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import '../../../helpers/fake_favourites.dart';
import '../../../helpers/test_l10n.dart';

// #277: the Show Activity Tracking toggle in Settings has been wired to
// hide every activity-related surface in the app. AddItemBottomSheet is
// the FAB's add-something menu — when the toggle is off, the Activity
// row at the top should disappear so the meal options are all that's on
// offer. Locking the behaviour in here so a future refactor that drops
// the conditional or its default trips the test instead of slipping past
// review.

Widget _wrapWithMaterial(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [S.delegate],
    supportedLocales: S.supportedLocales,
    home: Scaffold(body: child),
  );
}

class _FakeGetIntakeUsecase implements GetIntakeUsecase {
  @override
  Future<List<IntakeEntity>> getRecentIntake() async => [
    for (var i = 0; i < 2; i++)
      IntakeEntity(
        id: 'recent-$i',
        unit: 'g',
        amount: 100,
        type: IntakeTypeEntity.lunch,
        meal: MealEntity(
          code: 'recent-$i',
          name: 'Recent $i',
          url: null,
          mealQuantity: '100',
          mealUnit: 'g',
          servingQuantity: null,
          servingUnit: null,
          servingSize: null,
          nutriments: MealNutrimentsEntity.empty(),
          source: MealSourceEntity.custom,
        ),
        dateTime: DateTime(2026, 1, 1),
      ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

Finder _withIdentifier(String identifier) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.identifier == identifier,
);

void main() {
  testWidgets(
    'shows the Activity tile when showActivityTracking is true',
    (tester) async {
      await tester.pumpWidget(_wrapWithMaterial(
        AddItemBottomSheet(
          day: DateTime(2026, 1, 1),
          showActivityTracking: true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.activityLabel), findsOneWidget);
      expect(find.text(l10nEn.breakfastLabel), findsOneWidget);
    },
  );

  testWidgets(
    'hides the Activity tile when showActivityTracking is false',
    (tester) async {
      await tester.pumpWidget(_wrapWithMaterial(
        AddItemBottomSheet(
          day: DateTime(2026, 1, 1),
          showActivityTracking: false,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.activityLabel), findsNothing);
      // Meal tiles still render so the sheet stays useful for food logging.
      expect(find.text(l10nEn.breakfastLabel), findsOneWidget);
      expect(find.text(l10nEn.lunchLabel), findsOneWidget);
      expect(find.text(l10nEn.dinnerLabel), findsOneWidget);
      expect(find.text(l10nEn.snackLabel), findsOneWidget);
    },
  );

  testWidgets('recent card stars have unique identifiers', (tester) async {
    final getIt = GetIt.instance;
    await getIt.reset();
    final favourites = FakeFavourites();
    getIt.registerSingleton<GetIntakeUsecase>(_FakeGetIntakeUsecase());
    getIt.registerFactory<FavouriteToggleBloc>(
      () => FavouriteToggleBloc(favourites.get, favourites.toggle),
    );
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(_wrapWithMaterial(
      AddItemBottomSheet(day: DateTime(2026, 1, 1)),
    ));
    await tester.pumpAndSettle();

    expect(_withIdentifier('add-item-recent-favourite-1'), findsOneWidget);
    expect(_withIdentifier('add-item-recent-favourite-2'), findsOneWidget);
    handle.dispose();
    await getIt.reset();
    await favourites.dispose();
  });

  testWidgets(
    'defaults to showing the Activity tile when the flag is omitted',
    (tester) async {
      await tester.pumpWidget(_wrapWithMaterial(
        AddItemBottomSheet(day: DateTime(2026, 1, 1)),
      ));
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.activityLabel), findsOneWidget);
    },
  );

  // #580: launched from the global `+` action, the sheet preselects a
  // suggested meal type based on the current time. Only the matching tile
  // renders the "Suggested" chip; every tile stays tappable.
  testWidgets(
    'shows exactly one Suggested chip on the tile matching suggestedType',
    (tester) async {
      await tester.pumpWidget(_wrapWithMaterial(
        AddItemBottomSheet(
          day: DateTime(2026, 1, 1),
          suggestedType: IntakeTypeEntity.lunch,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.suggestedLabel), findsOneWidget);
      // The chip sits inside the Lunch ListTile, so a ListTile ancestor
      // above the chip must exist and its title must be the lunch label.
      final chipTile = find.ancestor(
        of: find.text(l10nEn.suggestedLabel),
        matching: find.byType(ListTile),
      );
      expect(chipTile, findsOneWidget);
      expect(
        find.descendant(of: chipTile, matching: find.text(l10nEn.lunchLabel)),
        findsOneWidget,
      );
    },
  );

  // #580: launched from a specific meal section (or when the caller has
  // already committed to a meal type), no suggestion is passed and no chip
  // should render, so nothing feels "preselected".
  // The chip is its own semantics node rather than part of the tile's, so
  // someone swiping through with TalkBack or VoiceOver lands on it directly.
  // Its Semantics wrapper sets a label and the Text inside says the same
  // word again; without excludeSemantics they both reach the node and it is
  // announced twice in a row.
  testWidgets(
    'announces the suggestion once, not twice',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrapWithMaterial(
        AddItemBottomSheet(
          day: DateTime(2026, 1, 1),
          suggestedType: IntakeTypeEntity.lunch,
        ),
      ));
      await tester.pumpAndSettle();

      final chip = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.identifier == 'add-item-suggested-chip',
      );
      final label = tester.semantics.find(chip).label;

      expect(label, equals(l10nEn.suggestedLabel),
          reason: 'the chip should say it once and only once');

      handle.dispose();
    },
  );

  testWidgets(
    'renders no Suggested chip when suggestedType is null',
    (tester) async {
      await tester.pumpWidget(_wrapWithMaterial(
        AddItemBottomSheet(day: DateTime(2026, 1, 1)),
      ));
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.suggestedLabel), findsNothing);
      // Meal tiles still render — the sheet remains fully usable.
      expect(find.text(l10nEn.breakfastLabel), findsOneWidget);
      expect(find.text(l10nEn.lunchLabel), findsOneWidget);
      expect(find.text(l10nEn.dinnerLabel), findsOneWidget);
      expect(find.text(l10nEn.snackLabel), findsOneWidget);
    },
  );
}
