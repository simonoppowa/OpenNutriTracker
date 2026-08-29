import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_table_calendar.dart';
import 'package:opennutritracker/generated/l10n.dart';

Widget _app({required double textScale}) => MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: DiaryTableCalendar(
            onDateSelected: (_, _) {},
            calendarDurationDays: const Duration(days: 365),
            focusedDate: DateTime(2026, 8, 24),
            currentDate: DateTime(2026, 8, 24),
            selectedDate: DateTime(2026, 8, 24),
            trackedDaysMap: const {},
          ),
        ),
      ),
    );

void main() {
  testWidgets('the weekday headings are not clipped at large font sizes',
      (tester) async {
    // #766. `TableCalendar`'s `daysOfWeekHeight` defaults to a flat 16.0,
    // and the headings are `labelSmall` — 11sp on a 1.45 line height, which
    // is exactly 16 logical pixels. The row therefore has *no* slack at the
    // default text size, and every step above it is clipped. Nothing throws
    // and no overflow stripes appear, because a fixed-height box clipping
    // its child is not a RenderFlex overflowing.
    for (final scale in const [1.0, 1.3, 1.5, 2.0]) {
      await tester.pumpWidget(_app(textScale: scale));
      await tester.pumpAndSettle();

      // The painted size cannot show this. Each heading sits in a
      // `SizedBox(height: daysOfWeekHeight)`, which is a *tight* constraint,
      // so the paragraph is squeezed to whatever the box allows and reports
      // that as its size however much it actually needs. Ask what it wants.
      final heading = tester.renderObject<RenderParagraph>(
        find.text('Mon').first,
      );
      final wanted = heading.getMaxIntrinsicHeight(heading.size.width);
      final given = tester
          .getSize(
            find
                .ancestor(of: find.text('Mon'), matching: find.byType(SizedBox))
                .first,
          )
          .height;

      expect(
        given,
        greaterThanOrEqualTo(wanted),
        reason: 'at ${scale}x a heading needs ${wanted}px and its row gives '
            '${given}px, so the top and bottom of the label are cut off',
      );
    }
  });
}
