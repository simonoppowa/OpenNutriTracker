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
  _FakeSettingsBloc({this.storedMl = 1500});

  final int storedMl;
  final List<int> saved = [];

  @override
  Future<int?> getDailyWaterGoalMl() async => storedMl;

  @override
  Future<void> setDailyWaterGoalMl(int goalMl) async => saved.add(goalMl);
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
    ReloadRecorder().register();
    settingsBloc = _FakeSettingsBloc();
    locator.registerSingleton<GetUserUsecase>(_FakeGetUserUsecase());
    locator.registerSingleton<ProfileBloc>(_FakeProfileBloc());
  });

  tearDown(() async => locator.reset());

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
                  usesImperialUnits: true,
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

  testWidgets('shows the stored ml goal in fl oz (#1306)', (tester) async {
    await openDialog(tester);

    // 1500 ml = 50.7 fl oz
    expect(find.widgetWithText(TextField, '51'), findsOneWidget);
    expect(find.text(l10nEn.flOzUnit), findsOneWidget);
  });

  testWidgets('saving untouched keeps the exact stored ml (#1306)', (
    tester,
  ) async {
    await openDialog(tester);

    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();

    expect(settingsBloc.saved, [1500]);
  });

  // The ml range (100–10000) reaches past the fl oz one (4–336) at both
  // ends: 10000 ml shows as 338 fl oz and 100 ml as 3. Clamping the shown
  // value before seeing it was untouched saved 9937 ml and 118 ml.
  for (final storedMl in [10000, 100]) {
    testWidgets('saving untouched keeps $storedMl ml at the range edge', (
      tester,
    ) async {
      settingsBloc = _FakeSettingsBloc(storedMl: storedMl);
      await openDialog(tester);

      await tester.tap(find.text(l10nEn.dialogOKLabel));
      await tester.pumpAndSettle();

      expect(settingsBloc.saved, [storedMl]);
    });
  }

  testWidgets('an unchanged value typed differently is shown canonically', (
    tester,
  ) async {
    await openDialog(tester);

    await tester.enterText(find.byType(TextField), '051');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, '51'), findsOneWidget);
    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();
    expect(settingsBloc.saved, [1500]);
  });

  testWidgets('a typed fl oz goal is stored in ml (#1306)', (tester) async {
    await openDialog(tester);

    await tester.enterText(find.byType(TextField), '64');
    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();

    // 64 fl oz = 1892.7 ml
    expect(settingsBloc.saved, [1893]);
  });
}
