import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
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
  final List<int> savedGoals = [];

  @override
  Future<int?> getDailyWaterGoalMl() async => 2000;

  @override
  Future<void> setDailyWaterGoalMl(int goalMl) async {
    savedGoals.add(goalMl);
  }

  @override
  void add(SettingsEvent event) {}
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
  late _FakeSettingsBloc settingsBloc;

  setUp(() {
    settingsBloc = _FakeSettingsBloc();
    locator.registerSingleton<GetUserUsecase>(_FakeGetUserUsecase());
    locator.registerSingleton<ProfileBloc>(_FakeProfileBloc());
    // Save reloads the Diary and Trends through the locator (#1359).
    ReloadRecorder().register();
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

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
                builder: (_) => WaterGoalDialog(
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

  // #1347: typing a value and tapping OK without the keyboard's Done key
  // used to save the slider's last value instead of the typed one.
  testWidgets('saves the typed water goal when OK is tapped without Done', (
    tester,
  ) async {
    await openDialog(tester);

    await tester.enterText(find.byType(TextField), '3250');
    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();

    expect(settingsBloc.savedGoals, [3250]);
    expect(find.byType(WaterGoalDialog), findsNothing);
  });

  testWidgets('clamps a typed water goal above the maximum on OK', (
    tester,
  ) async {
    await openDialog(tester);

    await tester.enterText(find.byType(TextField), '25000');
    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();

    expect(settingsBloc.savedGoals, [10000]);
  });
}
