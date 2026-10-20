import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_profiles_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/switch_profile_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_labels.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_snapshot.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_writer.dart';
import 'package:opennutritracker/features/profile/presentation/utils/profile_switch_coordinator.dart';
import 'package:opennutritracker/generated/l10n.dart';

class _FakeSwitchProfileUsecase extends Fake implements SwitchProfileUsecase {
  @override
  Future<void> switchProfile(ProfileEntity profile) async {}
}

/// A just-added profile: nothing onboarded yet.
class _EmptyUserRepository extends Fake implements UserRepository {
  @override
  Future<bool> hasUserData() async => false;
}

/// A profile that finished onboarding.
class _OnboardedUserRepository extends Fake implements UserRepository {
  @override
  Future<bool> hasUserData() async => true;
}

class _FakeGetProfilesUsecase extends Fake implements GetProfilesUsecase {
  @override
  String get activeProfileId => 'outgoing';
}

class _RecordingWidgetStore implements CalorieWidgetStore {
  final bool fails;
  int clears = 0;

  _RecordingWidgetStore({this.fails = false});

  @override
  int get generation => 0;

  @override
  Future<void> write(
    CalorieWidgetSnapshot snapshot,
    CalorieWidgetLabels labels, {
    int? generation,
  }) async {}

  @override
  Future<void> clear() async {
    clears++;
    if (fails) throw MissingPluginException('home_widget');
  }

  @override
  Future<void> relabel(S s) async {}
}

void main() {
  final fresh = ProfileEntity(
    id: 'fresh',
    name: 'Fresh',
    createdAt: DateTime(2026, 10, 1),
    boxSuffix: '_fresh',
  );

  setUp(() {
    locator.registerSingleton<GetProfilesUsecase>(_FakeGetProfilesUsecase());
  });

  tearDown(() async => locator.reset());

  Future<BuildContext> pumpHost(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          NavigationOptions.onboardingRoute: (_) => const Text('onboarding'),
        },
        home: Builder(
          builder: (ctx) {
            context = ctx;
            return const SizedBox();
          },
        ),
      ),
    );
    return context;
  }

  testWidgets('switching to an empty profile clears the calorie widget', (
    tester,
  ) async {
    // Home is not reloaded on this path, so nothing else would take the
    // outgoing profile's figures off the home screen.
    final store = _RecordingWidgetStore();
    final coordinator = ProfileSwitchCoordinator(
      _FakeSwitchProfileUsecase(),
      _EmptyUserRepository(),
      calorieWidgetStore: store,
    );
    final context = await pumpHost(tester);

    await coordinator.switchTo(context, fresh);
    await tester.pumpAndSettle();

    expect(store.clears, 1);
    expect(find.text('onboarding'), findsOneWidget);
  });

  testWidgets('a widget that cannot be cleared still reaches onboarding', (
    tester,
  ) async {
    final store = _RecordingWidgetStore(fails: true);
    final coordinator = ProfileSwitchCoordinator(
      _FakeSwitchProfileUsecase(),
      _EmptyUserRepository(),
      calorieWidgetStore: store,
    );
    final context = await pumpHost(tester);

    await coordinator.switchTo(context, fresh);
    await tester.pumpAndSettle();

    expect(store.clears, 1);
    expect(find.text('onboarding'), findsOneWidget);
  });

  testWidgets('switching to an onboarded profile from a screen that closed '
      'meanwhile still clears the calorie widget', (tester) async {
    // The Home reload that would republish the widget for the new profile
    // is skipped for an unmounted context, so without the clear the
    // outgoing profile's figures would stay on the home screen.
    final store = _RecordingWidgetStore();
    final coordinator = ProfileSwitchCoordinator(
      _FakeSwitchProfileUsecase(),
      _OnboardedUserRepository(),
      calorieWidgetStore: store,
    );
    final context = await pumpHost(tester);
    await tester.pumpWidget(const SizedBox());
    expect(context.mounted, isFalse, reason: 'setup');

    await coordinator.switchTo(context, fresh);

    expect(store.clears, 1);
  });
}
