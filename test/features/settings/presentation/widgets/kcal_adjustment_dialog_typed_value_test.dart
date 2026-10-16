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
  final List<double> savedAdjustments = [];

  /// The adjustment the dialog opens with, in kcal.
  double storedAdjustment = 0;

  @override
  Future<double> getKcalAdjustment() async => storedAdjustment;

  @override
  Future<void> setKcalAdjustment(double kcalAdjustment) async {
    savedAdjustments.add(kcalAdjustment);
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
  late _FakeSettingsBloc settingsBloc;

  setUp(() {
    settingsBloc = _FakeSettingsBloc();
  });

  Future<void> openDialog(
    WidgetTester tester, {
    bool usesKilojoules = false,
  }) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<EnergyUnitProvider>(
        create: (_) => EnergyUnitProvider(usesKilojoules: usesKilojoules),
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
  }

  // #1347: typing a value and tapping OK without the keyboard's Done key
  // used to save the slider's last value instead of the typed one.
  testWidgets(
    'saves the typed kcal adjustment when OK is tapped without Done',
    (tester) async {
      await openDialog(tester);

      await tester.enterText(find.byType(TextField), '250');
      await tester.tap(find.text(l10nEn.dialogOKLabel));
      await tester.pumpAndSettle();

      expect(settingsBloc.savedAdjustments, [250]);
      expect(find.byType(KcalAdjustmentDialog), findsNothing);
    },
  );

  testWidgets('converts a typed kJ adjustment to kcal on OK without Done', (
    tester,
  ) async {
    await openDialog(tester, usesKilojoules: true);

    await tester.enterText(find.byType(TextField), '1000');
    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();

    // 1000 kJ / 4.184 = 239.0 kcal, stored as a whole number.
    expect(settingsBloc.savedAdjustments, [239]);
  });

  // #1371 review: in kJ mode a stored 100 kcal shows as 418 kJ, which
  // converts back to 99.9 kcal and was saved truncated as 99. Text the
  // user did not edit is no longer re-parsed on OK.
  testWidgets('keeps a stored kcal adjustment when OK is tapped unedited in '
      'kJ mode', (tester) async {
    settingsBloc.storedAdjustment = 100;
    await openDialog(tester, usesKilojoules: true);

    expect(find.widgetWithText(TextField, '418'), findsOneWidget);
    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();

    expect(settingsBloc.savedAdjustments, [100]);
  });
}
