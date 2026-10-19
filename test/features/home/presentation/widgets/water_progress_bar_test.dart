import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/home/presentation/widgets/water_progress_bar.dart';
import 'package:opennutritracker/generated/l10n.dart';

void main() {
  Future<void> pumpBar(
    WidgetTester tester, {
    required int current,
    required int goal,
    Locale locale = const Locale('en'),
    double textScale = 1,
    double width = 400,
    VoidCallback? onTap,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 400),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: WaterProgressBar(
              currentMl: current,
              goalMl: goal,
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  double progress(WidgetTester tester) => tester
      .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
      .value!;

  testWidgets('shows the amount against the goal', (tester) async {
    await pumpBar(tester, current: 1200, goal: 2000);

    expect(find.text('1200 / 2000 ml'), findsOneWidget);
    expect(progress(tester), closeTo(0.6, 0.001));
  });

  testWidgets('a full bar beyond the goal, an empty one without goal', (
    tester,
  ) async {
    await pumpBar(tester, current: 2600, goal: 2000);
    expect(progress(tester), 1);

    await pumpBar(tester, current: 500, goal: 0);
    expect(progress(tester), 0);
  });

  testWidgets('a tap opens what the caller wants', (tester) async {
    var taps = 0;
    await pumpBar(tester, current: 0, goal: 2000, onTap: () => taps++);

    await tester.tap(find.bySemanticsIdentifier('water-progress'));

    expect(taps, 1);
  });

  testWidgets('large German text on a narrow screen does not overflow', (
    tester,
  ) async {
    await pumpBar(
      tester,
      current: 12500,
      goal: 10000,
      locale: const Locale('de'),
      textScale: 2.5,
      width: 280,
    );

    expect(tester.takeException(), isNull);
    final label = tester.renderObject<RenderParagraph>(
      find.text('12500 / 10000 ml'),
    );
    expect(
      label.didExceedMaxLines,
      isFalse,
      reason: 'both amounts stay readable',
    );
  });
}
