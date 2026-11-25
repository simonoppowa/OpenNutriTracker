import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horizontal_picker/horizontal_picker.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_weight_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';
import '../../../../helpers/test_l10n.dart';

/// Opens [SetWeightDialog] and returns a getter for what it popped.
Future<Object? Function()> _open(
  WidgetTester tester,
  BodyWeightUnit unit, {
  double initialKg = 87,
}) async {
  Object? popped;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => popped = await showDialog(
            context: context,
            builder: (_) => SetWeightDialog(initialKg: initialKg, unit: unit),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return () => popped;
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
}

/// Drags the ruler two ticks up (0.1 per tick, 60 px each). The drag starts
/// beside the centre, where the cursor mark would take the hit.
Future<void> _dragRulerUp(WidgetTester tester) async {
  final start = tester.getCenter(find.byType(HorizontalPicker));
  await tester.dragFrom(start + const Offset(100, 0), const Offset(-120, 0));
  await tester.pumpAndSettle();
}

Future<void> _tapOk(WidgetTester tester) async {
  await tester.tap(find.text(l10nEn.dialogOKLabel));
  await tester.pumpAndSettle();
}

TextButton _okButton(WidgetTester tester) => tester.widget<TextButton>(
  find.widgetWithText(TextButton, l10nEn.dialogOKLabel),
);

double _rulerOpacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find.ancestor(
        of: find.byType(HorizontalPicker),
        matching: find.byType(Opacity),
      ),
    )
    .opacity;

void main() {
  group('SetWeightDialog typed field', () {
    testWidgets('untouched, the ruler weight is saved', (tester) async {
      final popped = await _open(tester, BodyWeightUnit.kg);
      expect(find.byType(HorizontalPicker), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      await _tapOk(tester);
      expect(popped() as double, closeTo(87, 0.05));
    });

    testWidgets('a typed kg weight is saved', (tester) async {
      final popped = await _open(tester, BodyWeightUnit.kg);
      await _type(tester, '86.4');
      await _tapOk(tester);
      expect(popped(), 86.4);
    });

    testWidgets('a typed lb weight is saved in kg', (tester) async {
      final popped = await _open(tester, BodyWeightUnit.lb);
      await _type(tester, '190');
      await _tapOk(tester);
      expect(popped() as double, closeTo(86.18, 0.01));
    });

    testWidgets('ruler then typed: the typed weight is saved', (tester) async {
      final popped = await _open(tester, BodyWeightUnit.kg);
      await _dragRulerUp(tester);
      await _type(tester, '80');
      await _tapOk(tester);
      expect(popped(), 80);
    });

    testWidgets('typed then ruler: the field follows and the ruler is saved', (
      tester,
    ) async {
      final popped = await _open(tester, BodyWeightUnit.kg);
      await _type(tester, '80');
      expect(_rulerOpacity(tester), lessThan(1));
      await _dragRulerUp(tester);
      expect(_rulerOpacity(tester), 1);
      expect(find.widgetWithText(TextField, '87.2'), findsOneWidget);
      await _tapOk(tester);
      expect(popped() as double, closeTo(87.2, 0.05));
    });

    testWidgets('an out-of-range weight shows an error and disables OK', (
      tester,
    ) async {
      final popped = await _open(tester, BodyWeightUnit.kg);
      await _type(tester, '854');
      expect(find.text(l10nEn.onboardingWrongWeightLabel), findsOneWidget);
      expect(_okButton(tester).onPressed, isNull);

      await _type(tester, '85.4');
      expect(find.text(l10nEn.onboardingWrongWeightLabel), findsNothing);
      expect(_okButton(tester).onPressed, isNotNull);
      await _tapOk(tester);
      expect(popped(), 85.4);
    });

    testWidgets('the ruler is left out of semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, BodyWeightUnit.kg);
      expect(find.bySemanticsLabel(RegExp(r'^\d+(\.\d)?kg$')), findsNothing);
      expect(
        find.bySemanticsIdentifier('set-weight-dialog-weight-input'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('stones keep their own fields and no ruler', (tester) async {
      final popped = await _open(tester, BodyWeightUnit.st);
      expect(find.byType(HorizontalPicker), findsNothing);
      expect(find.byType(TextField), findsNWidgets(2));
      await tester.enterText(find.byType(TextField).first, '13');
      await tester.enterText(find.byType(TextField).last, '0');
      await tester.pump();
      await _tapOk(tester);
      expect(popped() as double, closeTo(82.55, 0.01));
    });
  });
}
