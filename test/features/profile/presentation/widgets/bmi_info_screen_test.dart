import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/bmi_info_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';
import '../../../../helpers/test_l10n.dart';

/// Renders the BMI transparency screen for fixed profiles and asserts the
/// displayed values against hand-computed BMI numbers, including the WHO
/// band boundaries — so the screen can never disagree with BMICalc or the
/// Profile tab's ring.
class _FakeGetUserUsecase extends Fake implements GetUserUsecase {
  final UserEntity user;

  _FakeGetUserUsecase(this.user);

  @override
  Future<UserEntity> getUserData() async => user;
}

UserEntity _buildUser({double weightKG = 80.0, double heightCM = 180.0}) {
  // Yesterday, not day - 1, so the birthday stays valid on the 1st of the
  // month; captured once to avoid a midnight rollover between now() calls.
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  return UserEntity(
    birthday: DateTime(yesterday.year - 30, yesterday.month, yesterday.day),
    heightCM: heightCM,
    weightKG: weightKG,
    gender: UserGenderEntity.male,
    goal: UserWeightGoalEntity.maintainWeight,
    pal: UserPALEntity.sedentary,
  );
}

Widget _wrap(UserEntity user) {
  return MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    home: BmiInfoScreen(userUsecase: _FakeGetUserUsecase(user)),
  );
}

/// The color the user's own classification row must carry.
Color _primaryOf(WidgetTester tester, Finder finder) =>
    Theme.of(tester.element(finder)).colorScheme.primary;

Future<void> _pump(WidgetTester tester, UserEntity user) async {
  // Tall viewport so the lazy ListView inflates the classification card
  // at the bottom of the screen.
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_wrap(user));
  await tester.pumpAndSettle();
}

void main() {
  group('BmiInfoScreen', () {
    testWidgets('shows inputs, substituted formula, and hand-computed BMI', (
      tester,
    ) async {
      // 80 kg / 1.80 m² = 24.6913… → 24.7 at one decimal.
      await _pump(tester, _buildUser());

      expect(find.text('180 cm'), findsOneWidget);
      expect(find.text('80.0 kg'), findsOneWidget);
      expect(find.textContaining('= 80.0 ÷ 1.80²'), findsOneWidget);
      expect(find.textContaining('= 24.7'), findsOneWidget);
      expect(find.text('24.7'), findsOneWidget);
    });

    testWidgets('all six WHO bands are listed with their ranges', (
      tester,
    ) async {
      await _pump(tester, _buildUser());

      expect(find.text('< 18.5'), findsOneWidget);
      expect(find.text('18.5 – 24.9'), findsOneWidget);
      expect(find.text('25.0 – 29.9'), findsOneWidget);
      expect(find.text('30.0 – 34.9'), findsOneWidget);
      expect(find.text('35.0 – 39.9'), findsOneWidget);
      expect(find.text('≥ 40.0'), findsOneWidget);
    });

    testWidgets('highlights exactly the user\'s WHO classification', (
      tester,
    ) async {
      // BMI 24.7 → normal weight.
      await _pump(tester, _buildUser());

      final normal = find.text(l10nEn.nutritionalStatusNormalWeight);
      final normalStyle = tester.widget<Text>(normal).style;
      expect(normalStyle?.fontWeight, FontWeight.bold);
      expect(normalStyle?.color, _primaryOf(tester, normal));

      final pre = find.text(l10nEn.nutritionalStatusPreObesity);
      expect(
        tester.widget<Text>(pre).style?.fontWeight,
        isNot(FontWeight.bold),
      );
    });

    testWidgets('the 25.0 boundary falls into pre-obesity, matching BMICalc', (
      tester,
    ) async {
      // 81 kg / 1.80 m² = 25.0 exactly — WHO/BMICalc classify this as
      // pre-obesity, not normal weight. Pins the boundary behaviour.
      await _pump(tester, _buildUser(weightKG: 81.0));

      expect(find.text('25.0'), findsOneWidget);

      final pre = find.text(l10nEn.nutritionalStatusPreObesity);
      final preStyle = tester.widget<Text>(pre).style;
      expect(preStyle?.fontWeight, FontWeight.bold);
      expect(preStyle?.color, _primaryOf(tester, pre));

      final normal = find.text(l10nEn.nutritionalStatusNormalWeight);
      expect(
        tester.widget<Text>(normal).style?.fontWeight,
        isNot(FontWeight.bold),
      );
    });
  });
}
