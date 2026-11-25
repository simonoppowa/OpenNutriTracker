import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/per_meal_kcal_share_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../helpers/test_l10n.dart';

class _FakeSettingsBloc extends Fake implements SettingsBloc {
  Map<String, int> stored = Map.of(ConfigEntity.defaultMealKcalSharesPct);
  final List<Map<String, int>> saved = [];

  @override
  Future<Map<String, int>> getMealKcalSharesPct() async => Map.of(stored);

  @override
  Future<void> setMealKcalSharesPct(Map<String, int> shares) async {
    saved.add(Map.of(shares));
    stored = Map.of(shares);
  }

  @override
  void add(SettingsEvent event) {}
}

class _FakeHomeBloc extends Fake implements HomeBloc {
  @override
  void add(HomeEvent event) {}
}

class _FakeCalendarDayBloc extends Fake implements CalendarDayBloc {
  @override
  void add(CalendarDayEvent event) {}
}

const _meals = [
  ConfigEntity.mealKeyBreakfast,
  ConfigEntity.mealKeyLunch,
  ConfigEntity.mealKeyDinner,
  ConfigEntity.mealKeySnack,
];

Finder _field(String meal) => find.descendant(
  of: find.bySemanticsIdentifier('meal-share-$meal-input'),
  matching: find.byType(TextField),
);

Finder _slider(String meal) => find.descendant(
  of: find.bySemanticsIdentifier('meal-share-$meal'),
  matching: find.byType(Slider),
);

void main() {
  late _FakeSettingsBloc settingsBloc;

  setUp(() => settingsBloc = _FakeSettingsBloc());

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => PerMealKcalShareDialog(
                  settingsBloc: settingsBloc,
                  homeBloc: _FakeHomeBloc(),
                  calendarDayBloc: _FakeCalendarDayBloc(),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Map<String, int> sliderValues(WidgetTester tester) => {
    for (final m in _meals) m: tester.widget<Slider>(_slider(m)).value.round(),
  };

  Map<String, String> fieldTexts(WidgetTester tester) => {
    for (final m in _meals)
      m: tester.widget<TextField>(_field(m)).controller!.text,
  };

  TextButton okButton(WidgetTester tester) => tester.widget<TextButton>(
    find.descendant(
      of: find.bySemanticsIdentifier('meal-share-save'),
      matching: find.byType(TextButton),
    ),
  );

  Future<void> type(WidgetTester tester, String meal, String text) async {
    await tester.ensureVisible(_field(meal));
    await tester.enterText(_field(meal), text);
    await tester.pump();
  }

  Future<void> tapOk(WidgetTester tester) async {
    await tester.ensureVisible(find.text(l10nEn.dialogOKLabel));
    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();
  }

  testWidgets('moving one slider leaves the other shares alone (#715)', (
    tester,
  ) async {
    await openDialog(tester);

    tester.widget<Slider>(_slider(ConfigEntity.mealKeyBreakfast)).onChanged!(
      23,
    );
    await tester.pump();

    expect(sliderValues(tester), {
      ConfigEntity.mealKeyBreakfast: 23,
      ConfigEntity.mealKeyLunch: 40,
      ConfigEntity.mealKeyDinner: 20,
      ConfigEntity.mealKeySnack: 10,
    });
    // The field follows its slider.
    expect(fieldTexts(tester)[ConfigEntity.mealKeyBreakfast], '23');
  });

  testWidgets('typing 23 / 26 / 30 / 21 saves exactly that split', (
    tester,
  ) async {
    await openDialog(tester);

    await type(tester, ConfigEntity.mealKeyBreakfast, '23');
    await type(tester, ConfigEntity.mealKeyLunch, '26');
    await type(tester, ConfigEntity.mealKeyDinner, '30');
    // Mid-way the shares add up to 89 %, and nothing was rebalanced.
    expect(find.text(l10nEn.mealShareTotalLabel(89)), findsOneWidget);
    expect(find.text(l10nEn.mealShareRemainingLabel(11)), findsOneWidget);
    expect(okButton(tester).onPressed, isNull);

    await type(tester, ConfigEntity.mealKeySnack, '21');
    // The sliders follow the typed values.
    expect(sliderValues(tester), {
      ConfigEntity.mealKeyBreakfast: 23,
      ConfigEntity.mealKeyLunch: 26,
      ConfigEntity.mealKeyDinner: 30,
      ConfigEntity.mealKeySnack: 21,
    });
    expect(find.text(l10nEn.mealShareTotalLabel(100)), findsOneWidget);
    expect(okButton(tester).onPressed, isNotNull);

    await tapOk(tester);

    expect(settingsBloc.saved, [
      {
        ConfigEntity.mealKeyBreakfast: 23,
        ConfigEntity.mealKeyLunch: 26,
        ConfigEntity.mealKeyDinner: 30,
        ConfigEntity.mealKeySnack: 21,
      },
    ]);
    expect(find.byType(PerMealKcalShareDialog), findsNothing);
  });

  testWidgets('a total above 100 % blocks OK and says by how much', (
    tester,
  ) async {
    await openDialog(tester);

    await type(tester, ConfigEntity.mealKeyBreakfast, '35');

    expect(find.text(l10nEn.mealShareTotalLabel(105)), findsOneWidget);
    expect(find.text(l10nEn.mealShareOverLabel(5)), findsOneWidget);
    expect(okButton(tester).onPressed, isNull);

    await tapOk(tester);
    expect(settingsBloc.saved, isEmpty);
    expect(find.byType(PerMealKcalShareDialog), findsOneWidget);
  });

  testWidgets('a total below 100 % blocks OK and says what is left', (
    tester,
  ) async {
    await openDialog(tester);

    tester.widget<Slider>(_slider(ConfigEntity.mealKeySnack)).onChanged!(7);
    await tester.pump();

    expect(find.text(l10nEn.mealShareTotalLabel(97)), findsOneWidget);
    expect(find.text(l10nEn.mealShareRemainingLabel(3)), findsOneWidget);
    expect(okButton(tester).onPressed, isNull);
  });

  group('rejects typed values that are not a whole percent', () {
    for (final entry in {
      'an empty field': '',
      'text': 'abc',
      'a value above 100': '101',
      'a decimal with a comma': '23,5',
      'a decimal with a point': '23.5',
    }.entries) {
      testWidgets(entry.key, (tester) async {
        await openDialog(tester);

        await type(tester, ConfigEntity.mealKeyBreakfast, entry.value);

        expect(find.text(l10nEn.mealShareInvalidValueLabel), findsOneWidget);
        expect(okButton(tester).onPressed, isNull);
        // The slider keeps the last valid value, and nothing else moved.
        expect(sliderValues(tester), ConfigEntity.defaultMealKcalSharesPct);

        // Fixing the field clears the error and enables OK again.
        await type(tester, ConfigEntity.mealKeyBreakfast, '30');
        expect(find.text(l10nEn.mealShareInvalidValueLabel), findsNothing);
        expect(okButton(tester).onPressed, isNotNull);
      });
    }

    testWidgets('a negative value never reaches the field', (tester) async {
      await openDialog(tester);

      await type(tester, ConfigEntity.mealKeyBreakfast, '-5');

      // The minus sign is filtered out, leaving 5.
      expect(fieldTexts(tester)[ConfigEntity.mealKeyBreakfast], '5');
      expect(sliderValues(tester)[ConfigEntity.mealKeyBreakfast], 5);
      expect(find.text(l10nEn.mealShareTotalLabel(75)), findsOneWidget);
      expect(okButton(tester).onPressed, isNull);
    });
  });

  testWidgets('Cancel discards the edits', (tester) async {
    await openDialog(tester);

    await type(tester, ConfigEntity.mealKeyBreakfast, '23');
    await type(tester, ConfigEntity.mealKeyLunch, '47');
    await tester.tap(find.text(l10nEn.dialogCancelLabel));
    await tester.pumpAndSettle();

    expect(settingsBloc.saved, isEmpty);
    expect(settingsBloc.stored, ConfigEntity.defaultMealKcalSharesPct);
    expect(find.byType(PerMealKcalShareDialog), findsNothing);
  });

  testWidgets('reopening the dialog shows the saved split', (tester) async {
    await openDialog(tester);
    await type(tester, ConfigEntity.mealKeyBreakfast, '23');
    await type(tester, ConfigEntity.mealKeyLunch, '26');
    await type(tester, ConfigEntity.mealKeyDinner, '30');
    await type(tester, ConfigEntity.mealKeySnack, '21');
    await tapOk(tester);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    const expected = {
      ConfigEntity.mealKeyBreakfast: 23,
      ConfigEntity.mealKeyLunch: 26,
      ConfigEntity.mealKeyDinner: 30,
      ConfigEntity.mealKeySnack: 21,
    };
    expect(sliderValues(tester), expected);
    expect(fieldTexts(tester), {
      for (final e in expected.entries) e.key: '${e.value}',
    });
  });

  testWidgets(
    'stored shares that add up to 99 % open as stored and need a fix',
    (tester) async {
      // An older build or an imported backup can hold a split that is off
      // by a rounding step; the backup reader tolerates up to 2 %.
      settingsBloc.stored = {
        ConfigEntity.mealKeyBreakfast: 33,
        ConfigEntity.mealKeyLunch: 33,
        ConfigEntity.mealKeyDinner: 33,
        ConfigEntity.mealKeySnack: 0,
      };
      await openDialog(tester);

      expect(sliderValues(tester), settingsBloc.stored);
      expect(find.text(l10nEn.mealShareTotalLabel(99)), findsOneWidget);
      expect(find.text(l10nEn.mealShareRemainingLabel(1)), findsOneWidget);
      expect(okButton(tester).onPressed, isNull);

      await type(tester, ConfigEntity.mealKeySnack, '1');
      await tapOk(tester);

      expect(settingsBloc.saved.single, {
        ConfigEntity.mealKeyBreakfast: 33,
        ConfigEntity.mealKeyLunch: 33,
        ConfigEntity.mealKeyDinner: 33,
        ConfigEntity.mealKeySnack: 1,
      });
    },
  );

  testWidgets('a preset fills every field and slider', (tester) async {
    await openDialog(tester);
    await type(tester, ConfigEntity.mealKeyBreakfast, 'x');

    await tester.ensureVisible(
      find.bySemanticsIdentifier('meal-share-preset-omad'),
    );
    await tester.tap(find.bySemanticsIdentifier('meal-share-preset-omad'));
    await tester.pump();

    final omad = fieldTexts(tester).map((k, v) => MapEntry(k, int.parse(v)));
    expect(omad, sliderValues(tester));
    expect(omad.values.fold<int>(0, (a, b) => a + b), 100);
    expect(find.text(l10nEn.mealShareInvalidValueLabel), findsNothing);
    expect(okButton(tester).onPressed, isNotNull);
  });
}
