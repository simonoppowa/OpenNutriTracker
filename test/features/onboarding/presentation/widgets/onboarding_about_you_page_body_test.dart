import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/onboarding/presentation/widgets/onboarding_about_you_page_body.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../helpers/test_l10n.dart';

/// The adult-equation notice on the birthday page. The calorie goal comes
/// from the IOM 2005 adult equations, so a 13-17 year old is told where the
/// number comes from rather than handed it silently.
void main() {
  final noticeText = l10nEn.onboardingAdultEquationNotice;

  Future<void> pumpFirstPage(WidgetTester tester, {DateTime? birthday}) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: OnboardingAboutYouPageBody(
            setPageContent: (_, _, _, _) {},
            initialBirthday: birthday,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  DateTime yearsAgo(int years) {
    final now = DateTime.now();
    return DateTime(now.year - years, now.month, now.day);
  }

  testWidgets('no birthday chosen yet shows no notice', (tester) async {
    await pumpFirstPage(tester);

    expect(find.text(noticeText), findsNothing);
  });

  testWidgets('a 15 year old sees the notice', (tester) async {
    await pumpFirstPage(tester, birthday: yearsAgo(15));

    expect(find.text(noticeText), findsOneWidget);
  });

  testWidgets('a 13 year old sees the notice', (tester) async {
    await pumpFirstPage(tester, birthday: yearsAgo(13));

    expect(find.text(noticeText), findsOneWidget);
  });

  testWidgets('an adult does not', (tester) async {
    await pumpFirstPage(tester, birthday: yearsAgo(30));

    expect(find.text(noticeText), findsNothing);
  });

  testWidgets('exactly 18 does not', (tester) async {
    await pumpFirstPage(tester, birthday: yearsAgo(18));

    expect(find.text(noticeText), findsNothing);
  });
}
