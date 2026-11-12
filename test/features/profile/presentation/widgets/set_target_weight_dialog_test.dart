import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horizontal_picker/horizontal_picker.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_target_weight_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';
import '../../../../helpers/test_l10n.dart';

/// Opens [SetTargetWeightDialog] and returns a getter for what it popped.
Future<TargetWeightDialogResult? Function()> _open(
  WidgetTester tester,
  BodyWeightUnit unit,
) async {
  TargetWeightDialogResult? popped;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => popped = await showDialog(
            context: context,
            builder: (_) => SetTargetWeightDialog(
              initialKg: 87.1,
              hasExistingTarget: false,
              unit: unit,
            ),
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

void main() {
  group('SetTargetWeightDialog typed field', () {
    testWidgets('a target far off can be typed', (tester) async {
      final popped = await _open(tester, BodyWeightUnit.kg);
      await _type(tester, '60');
      await _tapOk(tester);
      expect(popped()?.value, 60);
    });

    testWidgets('a typed lb target is saved in kg', (tester) async {
      final popped = await _open(tester, BodyWeightUnit.lb);
      await _type(tester, '150');
      await _tapOk(tester);
      expect(popped()?.value, closeTo(68.04, 0.01));
    });

    testWidgets('ruler then typed: the typed target is saved', (tester) async {
      final popped = await _open(tester, BodyWeightUnit.kg);
      await _dragRulerUp(tester);
      await _type(tester, '80');
      await _tapOk(tester);
      expect(popped()?.value, 80);
    });

    testWidgets('typed then ruler: the ruler target is saved', (tester) async {
      final popped = await _open(tester, BodyWeightUnit.kg);
      await _type(tester, '80');
      await _dragRulerUp(tester);
      expect(find.widgetWithText(TextField, '87.3'), findsOneWidget);
      await _tapOk(tester);
      expect(popped()?.value, closeTo(87.3, 0.05));
    });

    testWidgets('an out-of-range target shows an error and disables OK', (
      tester,
    ) async {
      await _open(tester, BodyWeightUnit.kg);
      await _type(tester, '800');
      expect(find.text(l10nEn.onboardingWrongWeightLabel), findsOneWidget);
      final ok = tester.widget<TextButton>(
        find.widgetWithText(TextButton, l10nEn.dialogOKLabel),
      );
      expect(ok.onPressed, isNull);
      await _tapOk(tester);
      expect(find.byType(SetTargetWeightDialog), findsOneWidget);
    });

    testWidgets('stones keep their own fields and no ruler', (tester) async {
      await _open(tester, BodyWeightUnit.st);
      expect(find.byType(HorizontalPicker), findsNothing);
      expect(find.byType(TextField), findsNWidgets(2));
    });
  });
}
