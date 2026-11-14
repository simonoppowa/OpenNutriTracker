import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_custom_activity_template_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_activity_usercase.dart';
import 'package:opennutritracker/core/domain/usecase/get_custom_activity_templates_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/activity_detail/activity_detail_screen.dart';
import 'package:opennutritracker/features/activity_detail/presentation/bloc/activity_detail_bloc.dart';
import 'package:opennutritracker/features/activity_detail/presentation/widget/activity_detail_bottom_sheet.dart';
import 'package:opennutritracker/features/activity_detail/presentation/widget/activity_title_expanded.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../fixture/physical_activity_entity_fixtures.dart';
import '../../../fixture/user_entity_fixtures.dart';

/// The activity detail screen paints its canvas colour behind the status bar
/// and the home indicator.
///
/// A `SafeArea` around the whole `Scaffold` shrank the page to the safe
/// rectangle, so nothing painted the insets and they showed as black bars on
/// iPhones. The page now fills the screen; the pinned app bar keeps its
/// content below the status bar and the bottom sheet keeps Add above the
/// home indicator.
void main() {
  final getIt = GetIt.instance;

  // A large iPhone with a Dynamic Island: 430 x 932 points, 59 pt status
  // bar, 34 pt home indicator.
  const screen = Size(430, 932);
  const topInset = 59.0;
  const bottomInset = 34.0;
  const keyboardHeight = 300.0;
  const devicePixelRatio = 3.0;

  setUp(() {
    getIt.registerFactory<ActivityDetailBloc>(
      () => ActivityDetailBloc(
        _FakeGetUserUsecase(),
        _FakeAddUserActivityUsecase(),
        _FakeAddTrackedDayUsecase(),
        _FakeGetKcalGoalUsecase(),
        _FakeGetMacroGoalUsecase(),
        _FakeAddCustomActivityTemplateUsecase(),
        _FakeGetCustomActivityTemplatesUsecase(),
      ),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pumpActivityDetail(
    WidgetTester tester,
    Brightness brightness,
  ) async {
    tester.view.physicalSize = screen * devicePixelRatio;
    tester.view.devicePixelRatio = devicePixelRatio;
    tester.view.padding = const FakeViewPadding(
      top: topInset * devicePixelRatio,
      bottom: bottomInset * devicePixelRatio,
    );
    tester.view.viewPadding = const FakeViewPadding(
      top: topInset * devicePixelRatio,
      bottom: bottomInset * devicePixelRatio,
    );
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<EnergyUnitProvider>(
        create: (_) => EnergyUnitProvider(),
        child: MaterialApp(
          theme: ThemeData(brightness: brightness),
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          onGenerateInitialRoutes: (_) => [
            MaterialPageRoute<void>(
              settings: RouteSettings(
                arguments: ActivityDetailScreenArguments(
                  PhysicalActivityFixtures.moderateBicycling,
                  DateTime(2026, 10, 25),
                ),
              ),
              builder: (_) => const ActivityDetailScreen(),
            ),
          ],
          // Without a route factory MaterialApp builds no Navigator at all.
          onGenerateRoute: (_) => null,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final (brightness, palette) in [
    (Brightness.light, AppPalette.light),
    (Brightness.dark, AppPalette.dark),
  ]) {
    group('in ${brightness.name} theme', () {
      final activityDetailScaffold = find.descendant(
        of: find.byType(ActivityDetailScreen),
        matching: find.byType(Scaffold),
      );
      final bottomSheet = find.descendant(
        of: find.byType(ActivityDetailBottomSheet),
        matching: find.byType(BottomSheet),
      );
      final add = find.descendant(
        of: bottomSheet,
        matching: find.byIcon(Icons.add_rounded),
      );

      testWidgets('the page fills the status bar and home indicator areas', (
        tester,
      ) async {
        await pumpActivityDetail(tester, brightness);

        expect(
          tester.getRect(activityDetailScaffold.first),
          Offset.zero & screen,
          reason: 'the page must cover the insets, or they show black',
        );
        expect(
          tester.widget<Scaffold>(activityDetailScaffold.first).backgroundColor,
          palette.canvas,
        );
        final appBar = find.descendant(
          of: find.byType(ActivityDetailScreen),
          matching: find.byType(AppBar),
        );
        expect(tester.getRect(appBar).top, 0);
        expect(tester.widget<AppBar>(appBar).backgroundColor, palette.canvas);
        expect(
          tester.getRect(bottomSheet).bottom,
          screen.height,
          reason: 'the sheet surface paints behind the home indicator',
        );
      });

      testWidgets('the header and Add stay inside the safe area', (
        tester,
      ) async {
        await pumpActivityDetail(tester, brightness);

        final title = find.descendant(
          of: find.byType(ActivityTitleExpanded),
          matching: find.byType(RichText),
        );
        expect(tester.getRect(title.first).top, greaterThanOrEqualTo(topInset));
        expect(
          tester.getRect(add).bottom,
          lessThanOrEqualTo(screen.height - bottomInset),
        );
      });

      testWidgets('with the keyboard up, the sheet drops the home indicator '
          'gap', (tester) async {
        await pumpActivityDetail(tester, brightness);
        final gapWithoutKeyboard =
            tester.getRect(bottomSheet).bottom - tester.getRect(add).bottom;

        // As on a device: the keyboard covers the home indicator, so the
        // engine reports no bottom padding while it is up.
        tester.view.viewInsets = const FakeViewPadding(
          bottom: keyboardHeight * devicePixelRatio,
        );
        tester.view.padding = const FakeViewPadding(
          top: topInset * devicePixelRatio,
        );
        await tester.pumpAndSettle();

        expect(
          tester.getRect(bottomSheet).bottom,
          screen.height - keyboardHeight,
        );
        expect(
          tester.getRect(bottomSheet).bottom - tester.getRect(add).bottom,
          gapWithoutKeyboard - bottomInset,
        );
      });
    });
  }
}

class _FakeGetUserUsecase implements GetUserUsecase {
  @override
  Future<UserEntity> getUserData() async =>
      UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeAddUserActivityUsecase implements AddUserActivityUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeAddTrackedDayUsecase implements AddTrackedDayUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetKcalGoalUsecase implements GetKcalGoalUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetMacroGoalUsecase implements GetMacroGoalUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeAddCustomActivityTemplateUsecase
    implements AddCustomActivityTemplateUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetCustomActivityTemplatesUsecase
    implements GetCustomActivityTemplatesUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}
