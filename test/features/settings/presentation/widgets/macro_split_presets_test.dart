import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/macro_split_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';
import '../../../../helpers/fake_reload_blocs.dart';
import '../../../../helpers/test_l10n.dart';

class _FakeSettingsBloc extends Fake implements SettingsBloc {
  double? savedCarbs;
  double? savedProtein;
  double? savedFat;

  @override
  Future<double?> getUserCarbGoalPct() async => 0.6;

  @override
  Future<double?> getUserProteinGoalPct() async => 0.15;

  @override
  Future<double?> getUserFatGoalPct() async => 0.25;

  @override
  Future<void> setMacroGoals(
    double carbGoalPct,
    double proteinGoalPct,
    double fatGoalPct,
  ) async {
    savedCarbs = carbGoalPct;
    savedProtein = proteinGoalPct;
    savedFat = fatGoalPct;
  }

  @override
  Future<DateTime> getCurrentLogicalDay() async => DateTime(2026, 11, 10);

  @override
  Future<void> updateTrackedDay(DateTime day) async {}

  @override
  void add(SettingsEvent event) {}
}

class _FakeHomeBloc extends Fake implements HomeBloc {
  @override
  void add(HomeEvent event) {}
}

Future<void> _openDialog(WidgetTester tester, SettingsBloc settingsBloc) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => MacroSplitDialog(
                settingsBloc: settingsBloc,
                homeBloc: _FakeHomeBloc(),
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

List<String> _fieldValues(WidgetTester tester) => tester
    .widgetList<TextField>(find.byType(TextField))
    .map((field) => field.controller!.text)
    .toList();

Finder _preset(String id) =>
    find.bySemanticsIdentifier('macro-split-preset-$id');

void main() {
  setUp(() => ReloadRecorder().register());

  tearDown(() async => locator.reset());

  testWidgets('shows a button for every preset', (tester) async {
    await _openDialog(tester, _FakeSettingsBloc());

    expect(find.text(l10nEn.mealPatternPresetsLabel), findsOneWidget);
    for (final id in [
      'standard',
      'mediterranean',
      'high_protein',
      'low_carb',
      'keto',
    ]) {
      expect(_preset(id), findsOneWidget, reason: id);
    }
  });

  testWidgets('a preset fills in all three fields', (tester) async {
    await _openDialog(tester, _FakeSettingsBloc());

    await tester.tap(_preset('high_protein'));
    await tester.pumpAndSettle();

    expect(_fieldValues(tester), ['45', '30', '25']);
  });

  testWidgets('OK saves the preset split', (tester) async {
    final settingsBloc = _FakeSettingsBloc();
    await _openDialog(tester, settingsBloc);

    await tester.tap(_preset('keto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();

    expect(settingsBloc.savedCarbs, 5);
    expect(settingsBloc.savedProtein, 20);
    expect(settingsBloc.savedFat, 75);
  });

  testWidgets('Cancel after a preset saves nothing', (tester) async {
    final settingsBloc = _FakeSettingsBloc();
    await _openDialog(tester, settingsBloc);

    await tester.tap(_preset('low_carb'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.dialogCancelLabel));
    await tester.pumpAndSettle();

    expect(settingsBloc.savedCarbs, isNull);
  });

  testWidgets('a typed value after a preset is applied on save', (
    tester,
  ) async {
    final settingsBloc = _FakeSettingsBloc();
    await _openDialog(tester, settingsBloc);

    await tester.tap(_preset('mediterranean'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '55');
    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();

    // 55 / residual 45 split 20:35 → 16.36 / 28.64, rounded to sum 100.
    expect(settingsBloc.savedCarbs, 55);
    expect(settingsBloc.savedProtein, 16);
    expect(settingsBloc.savedFat, 29);
  });

  testWidgets('the low-carb note shows only for low carb and keto', (
    tester,
  ) async {
    await _openDialog(tester, _FakeSettingsBloc());
    final note = find.text(l10nEn.macroPresetLowCarbNote);

    expect(note, findsNothing);

    await tester.tap(_preset('keto'));
    await tester.pumpAndSettle();
    expect(note, findsOneWidget);

    await tester.tap(_preset('low_carb'));
    await tester.pumpAndSettle();
    expect(note, findsOneWidget);

    await tester.tap(_preset('standard'));
    await tester.pumpAndSettle();
    expect(note, findsNothing);
  });
}
