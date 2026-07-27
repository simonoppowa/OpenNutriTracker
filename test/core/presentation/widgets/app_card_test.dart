import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/dimens.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('AppCard', () {
    testWidgets(
        'clipping Material spans the whole card, not the padded content box '
        '(regression: padding on the Container shrank the Material while the '
        'clip kept the full corner radius, so the arc curved in over the '
        'content and sliced the first glyph of text in a card corner — the '
        'home macro totals rendered "89/79 g" as "39/79 g")',
        (tester) async {
      const radius = 20.0;
      const padding = EdgeInsets.all(16);

      await tester.pumpWidget(_wrap(
        const AppCard(
          borderRadius: radius,
          padding: padding,
          child: SizedBox(width: 100, height: 40),
        ),
      ));

      final cardSize = tester.getSize(find.byType(AppCard));
      final clipMaterial = find.descendant(
        of: find.byType(AppCard),
        matching: find.byWidgetPredicate(
          (w) => w is Material && w.clipBehavior == Clip.antiAlias,
        ),
      );

      expect(clipMaterial, findsOneWidget);
      // The Material fills the card short of its hairline border. If it were
      // inside the padding instead it would measure the content box (100x40)
      // rather than 132x72, and the corner arc would eat into the child.
      expect(
        tester.getSize(clipMaterial),
        Size(cardSize.width - 2 * Dimens.hairline,
            cardSize.height - 2 * Dimens.hairline),
      );
    });

    testWidgets('padding still spaces the child away from the card edge',
        (tester) async {
      const padding = EdgeInsets.all(16);

      await tester.pumpWidget(_wrap(
        const AppCard(
          padding: padding,
          child: SizedBox(width: 100, height: 40),
        ),
      ));

      final card = tester.getRect(find.byType(AppCard));
      final child = tester.getRect(find.byType(SizedBox).last);
      const inset = Dimens.hairline; // the bordered decoration

      expect(child.left - card.left, padding.left + inset);
      expect(child.top - card.top, padding.top + inset);
      expect(card.right - child.right, padding.right + inset);
      expect(card.bottom - child.bottom, padding.bottom + inset);
    });
  });
}
