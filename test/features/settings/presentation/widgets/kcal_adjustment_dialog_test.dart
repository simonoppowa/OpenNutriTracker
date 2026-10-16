import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/kcal_adjustment_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../../fixture/user_entity_fixtures.dart';
import '../../../../helpers/test_l10n.dart';

class _FakeSettingsBloc extends Fake implements SettingsBloc {
  double? saved;

  @override
  Future<double> getKcalAdjustment() async => 100;

  @override
  Future<void> setKcalAdjustment(double kcalAdjustment) async {
    saved = kcalAdjustment;
  }

  @override
  Future<void> updateTrackedDay(DateTime day) async {}

  @override
  void add(SettingsEvent event) {}
}

class _FakeProfileBloc extends Fake implements ProfileBloc {
  @override
  Future<UserEntity> getUser() async =>
      UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight;
}

class _FakeHomeBloc extends Fake implements HomeBloc {
  @override
  void add(HomeEvent event) {}
}

Widget _wrap(EnergyUnitProvider units, Widget child) {
  return ChangeNotifierProvider<EnergyUnitProvider>.value(
    value: units,
    child: MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

/// Opens the dialog with 100 kcal stored, runs [interact] on the open
/// dialog, then taps OK.
Future<_FakeSettingsBloc> _openAndSave(
  WidgetTester tester, {
  bool usesKj = false,
  Future<void> Function(WidgetTester tester, EnergyUnitProvider units)?
  interact,
}) async {
  final settingsBloc = _FakeSettingsBloc();
  final units = EnergyUnitProvider(usesKilojoules: usesKj);
  await tester.pumpWidget(
    _wrap(
      units,
      Builder(
        builder: (context) {
          return ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => KcalAdjustmentDialog(
                settingsBloc: settingsBloc,
                profileBloc: _FakeProfileBloc(),
                homeBloc: _FakeHomeBloc(),
              ),
            ),
            child: const Text('Open'),
          );
        },
      ),
    ),
  );

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();

  if (interact != null) await interact(tester, units);

  await tester.tap(find.text(l10nEn.dialogOKLabel));
  await tester.pumpAndSettle();
  return settingsBloc;
}

Future<void> Function(WidgetTester, EnergyUnitProvider) _type(String text) =>
    (tester, _) => tester.enterText(find.byType(TextField), text);

void main() {
  testWidgets('saves a typed adjustment even without submitting the field', (
    tester,
  ) async {
    final settingsBloc = await _openAndSave(tester, interact: _type('-250'));
    expect(settingsBloc.saved, -250);
  });

  testWidgets('clamps a typed adjustment to the slider range on save', (
    tester,
  ) async {
    final settingsBloc = await _openAndSave(tester, interact: _type('5000'));
    expect(settingsBloc.saved, 1000);
  });

  testWidgets('keeps the loaded adjustment when the typed value is empty', (
    tester,
  ) async {
    final settingsBloc = await _openAndSave(tester, interact: _type(''));
    expect(settingsBloc.saved, 100);
  });

  testWidgets('saves a typed kJ value converted to kcal', (tester) async {
    // 2092 kJ / 4.184 = 500 kcal exactly.
    final settingsBloc = await _openAndSave(
      tester,
      usesKj: true,
      interact: _type('2092'),
    );
    expect(settingsBloc.saved, 500);
  });

  testWidgets('an untouched field in kJ mode does not drift the stored kcal', (
    tester,
  ) async {
    // The field shows the kJ value rounded (100 kcal → "418"); re-parsing
    // that on save would store 99. OK without editing must keep 100.
    final settingsBloc = await _openAndSave(tester, usesKj: true);
    expect(settingsBloc.saved, 100);
  });

  testWidgets('a slider-set value in kJ mode is saved exactly', (tester) async {
    // 209.2 kJ is a slider step (5 × 41.84) = 50 kcal. The field then
    // shows "209", which re-parsed would be 49.95 → 49.
    final settingsBloc = await _openAndSave(
      tester,
      usesKj: true,
      interact: (tester, _) async {
        tester.widget<Slider>(find.byType(Slider)).onChanged!(209.2);
        await tester.pump();
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          '209',
        );
      },
    );
    expect(settingsBloc.saved, 50);
  });

  testWidgets('a unit switch while open rewrites the field in the new unit', (
    tester,
  ) async {
    // Field shows "418" (kJ). After the unit flips to kcal it must read
    // "100", and pressing Done on it (which parses the field) followed
    // by OK must save 100 kcal, not 418.
    final settingsBloc = await _openAndSave(
      tester,
      usesKj: true,
      interact: (tester, units) async {
        final field = find.byType(TextField);
        expect(tester.widget<TextField>(field).controller!.text, '418');
        units.updateUsesKilojoules(false);
        await tester.pump();
        expect(tester.widget<TextField>(field).controller!.text, '100');
        tester.widget<TextField>(field).onEditingComplete!();
        await tester.pump();
      },
    );
    expect(settingsBloc.saved, 100);
  });
}
