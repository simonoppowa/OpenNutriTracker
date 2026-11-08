import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/kcal_adjustment_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../../fixture/user_entity_fixtures.dart';
import '../../../../helpers/fake_reload_blocs.dart';
import '../../../../helpers/test_l10n.dart';

class _FakeSettingsBloc extends Fake implements SettingsBloc {
  final List<String> calls;

  _FakeSettingsBloc(this.calls);

  @override
  Future<double> getKcalAdjustment() async => 0;

  @override
  Future<void> setKcalAdjustment(double kcalAdjustment) async {}

  @override
  Future<DateTime> getCurrentLogicalDay() async => DateTime(2026, 10, 10);

  @override
  Future<void> updateTrackedDay(DateTime day) async {
    // A real write yields; make sure the reload cannot overtake it.
    await Future<void>.delayed(Duration.zero);
    calls.add('updateTrackedDay');
  }

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
  late ReloadRecorder recorder;

  setUp(() {
    recorder = ReloadRecorder()..register();
  });

  tearDown(() async => locator.reset());

  testWidgets(
    'saving reloads the Diary, the open day and Trends after today\'s '
    'tracked day has its new goal (#1359)',
    (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<EnergyUnitProvider>(
          create: (_) => EnergyUnitProvider(),
          child: MaterialApp(
            localizationsDelegates: const [S.delegate],
            supportedLocales: S.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => KcalAdjustmentDialog(
                      settingsBloc: _FakeSettingsBloc(recorder.log),
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

      await tester.tap(find.text(l10nEn.dialogOKLabel));
      await tester.pumpAndSettle();

      expect(recorder.diaryReloaded, isTrue);
      expect(recorder.calendarDayReloaded, isTrue);
      expect(recorder.trendsReloaded, isTrue);
      // The views read the tracked day, so they must reload after it is
      // rewritten — never before.
      expect(recorder.log.first, 'updateTrackedDay');
    },
  );
}
