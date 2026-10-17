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
  final double stored;
  double? saved;

  _FakeSettingsBloc(this.stored);

  @override
  Future<double> getKcalAdjustment() async => stored;

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

void main() {
  Future<_FakeSettingsBloc> openDialog(
    WidgetTester tester, {
    double stored = 0,
    bool usesKj = false,
  }) async {
    final settingsBloc = _FakeSettingsBloc(stored);
    await tester.pumpWidget(
      ChangeNotifierProvider<EnergyUnitProvider>.value(
        value: EnergyUnitProvider(usesKilojoules: usesKj),
        child: MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => KcalAdjustmentDialog(
                    settingsBloc: settingsBloc,
                    profileBloc: _FakeProfileBloc(),
                    homeBloc: _FakeHomeBloc(),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return settingsBloc;
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();
  }

  testWidgets('saves a typed value without a submit', (tester) async {
    // #1324: the iOS number pad has no return key, so onSubmitted never
    // fires there. Typing and tapping OK has to be enough.
    final settingsBloc = await openDialog(tester);

    await tester.enterText(find.byType(TextField), '-300');
    await save(tester);

    expect(settingsBloc.saved, -300);
  });

  testWidgets('applies a typed value when the field loses focus', (
    tester,
  ) async {
    await openDialog(tester);

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '250');
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    expect(tester.widget<Slider>(find.byType(Slider)).value, 250);
  });

  testWidgets('an untouched kJ field does not shift the saved value', (
    tester,
  ) async {
    // 100 kcal shows as 418 kJ, which reads back as 99.9 kcal. Only text
    // the user typed may be applied, or every save would creep downwards.
    final settingsBloc = await openDialog(tester, stored: 100, usesKj: true);

    await save(tester);

    expect(settingsBloc.saved, 100);
  });

  testWidgets('a slider move after typing wins over the typed text', (
    tester,
  ) async {
    final settingsBloc = await openDialog(tester, stored: 100, usesKj: true);

    await tester.enterText(find.byType(TextField), '2000');
    tester.widget<Slider>(find.byType(Slider)).onChanged!(100 * 4.184);
    await tester.pump();
    await save(tester);

    expect(settingsBloc.saved, 100);
  });
}
