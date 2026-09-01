import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/presentation/widgets/badged_title.dart';

/// [BadgedTitle] carries AGENTS.md's "row titles must not overflow" rule for
/// every screen that shows a badge, so the rule is measured here once rather
/// than re-argued per row. #728.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required double width,
    required String title,
    String? badge,
    double textScale = 1.0,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Center(
              child: SizedBox(
                width: width,
                child: BadgedTitle(title: title, badge: badge),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('a badge wider than its row drops to a line of its own', (
    tester,
  ) async {
    // The case a `Row` could not answer. Bounding the title does nothing when
    // the badge alone exceeds the width, which is what happens at 2x text
    // scale in German: "Experimentell" overflowed the onboarding row by 79
    // pixels however far the title shrank.
    await pump(
      tester,
      width: 150,
      title: 'KI-Unterstützung',
      badge: 'Experimentell',
      textScale: 2.0,
    );

    expect(tester.takeException(), isNull);
    // Both texts intact — the point of wrapping rather than truncating.
    expect(find.text('Experimentell'), findsOneWidget);
    expect(find.text('KI-Unterstützung'), findsOneWidget);
  });

  testWidgets('a long title still ellipsizes rather than wrapping silently', (
    tester,
  ) async {
    // The half of the rule that has not changed: a title may be clipped, but
    // it may never grow the row by wrapping to a second line.
    await pump(
      tester,
      width: 160,
      title: 'A settings row title far too long to fit in this width',
      badge: 'Experimental',
    );

    expect(tester.takeException(), isNull);
    final text = tester.widget<Text>(find.textContaining('A settings row'));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });

  testWidgets('no badge means no wrapper at all', (tester) async {
    // Rows without a badge must keep behaving exactly as they did before this
    // widget existed, including their own wrapping.
    await pump(tester, width: 200, title: 'Plain title');

    expect(find.byType(Wrap), findsNothing);
    expect(tester.widget<Text>(find.text('Plain title')).maxLines, isNull);
  });

  testWidgets('both fit on one line at ordinary sizes', (tester) async {
    // The layout is unchanged where it already fitted; wrapping is a release
    // valve, not the normal case.
    // 403px is where this pair stops fitting, measured: the title's
    // intrinsic width is 256.5, the badge's 138, plus 8 of spacing.
    await pump(
      tester,
      width: 420,
      title: 'AI meal assistance',
      badge: 'Experimental',
    );

    expect(tester.takeException(), isNull);
    final title = tester.getRect(find.text('AI meal assistance'));
    final badge = tester.getRect(find.text('Experimental'));
    expect(
      badge.left,
      greaterThan(title.right - 1),
      reason: 'badge sits beside the title, not beneath it',
    );
    expect((badge.center.dy - title.center.dy).abs(), lessThan(2));
  });
}
