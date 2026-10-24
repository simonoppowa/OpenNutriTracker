import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/activity_detail/presentation/widget/activity_info_button.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_info_button.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../helpers/test_l10n.dart';

const _channel = MethodChannel('plugins.flutter.io/url_launcher');

Future<void> pumpAndTap(WidgetTester tester, Widget button) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    home: Scaffold(body: Center(child: button)),
  ));
  await tester.tap(find.byType(TextButton));
  await tester.pumpAndSettle();
}

void mockLauncher(Future<Object?> Function(MethodCall call) handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, handler);
}

void main() {
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  final buttons = <String, Widget>{
    'meal info button': const MealInfoButton(
      url: 'https://example.org/food',
      source: MealSourceEntity.off,
    ),
    'activity info button': const ActivityInfoButton(),
  };

  for (final entry in buttons.entries) {
    group(entry.key, () {
      testWidgets('shows an error instead of throwing when no app can open it',
          (tester) async {
        mockLauncher((call) async {
          throw PlatformException(code: 'ACTIVITY_NOT_FOUND');
        });

        await pumpAndTap(tester, entry.value);

        expect(find.text(l10nEn.errorOpeningBrowser), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('says nothing when the link opens', (tester) async {
        mockLauncher((call) async => true);

        await pumpAndTap(tester, entry.value);

        expect(find.byType(SnackBar), findsNothing);
      });
    });
  }

  testWidgets('a meal URL the platform rejects shows an error, not a crash',
      (tester) async {
    mockLauncher((call) async {
      throw PlatformException(
        code: 'argument_error',
        message: 'Unable to parse URL',
      );
    });

    await pumpAndTap(
      tester,
      const MealInfoButton(url: 'not a url', source: MealSourceEntity.off),
    );

    expect(find.text(l10nEn.errorOpeningBrowser), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
