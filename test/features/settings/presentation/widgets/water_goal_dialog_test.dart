import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/water_goal_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../fixture/user_entity_fixtures.dart';
import '../../../../helpers/fake_reload_blocs.dart';
import '../../../../helpers/test_l10n.dart';

class _FakeSettingsBloc extends Fake implements SettingsBloc {
  final List<String> calls;

  _FakeSettingsBloc(this.calls);

  @override
  Future<int?> getDailyWaterGoalMl() async => 1500;

  @override
  Future<void> setDailyWaterGoalMl(int goalMl) async {
    await Future<void>.delayed(Duration.zero);
    calls.add('setDailyWaterGoalMl');
  }
}

class _FakeGetUserUsecase extends Fake implements GetUserUsecase {
  @override
  Future<UserEntity> getUserData() async =>
      UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight;
}

class _FakeProfileBloc extends Fake implements ProfileBloc {
  @override
  void add(ProfileEvent event) {}
}

class _FakeHomeBloc extends Fake implements HomeBloc {
  @override
  void add(HomeEvent event) {}
}

void main() {
  late ReloadRecorder recorder;

  setUp(() {
    recorder = ReloadRecorder()..register();
    locator.registerSingleton<GetUserUsecase>(_FakeGetUserUsecase());
    locator.registerSingleton<ProfileBloc>(_FakeProfileBloc());
  });

  tearDown(() async => locator.reset());

  testWidgets(
    'saving reloads Trends so its water card shows the new goal (#1359)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => WaterGoalDialog(
                    settingsBloc: _FakeSettingsBloc(recorder.log),
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

      await tester.tap(find.text(l10nEn.dialogOKLabel));
      await tester.pumpAndSettle();

      expect(recorder.trendsReloaded, isTrue);
      expect(recorder.log.first, 'setDailyWaterGoalMl');
    },
  );
}
