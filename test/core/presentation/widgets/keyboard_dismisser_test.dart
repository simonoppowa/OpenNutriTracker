import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/presentation/widgets/keyboard_dismisser.dart';

void main() {
  var buttonPresses = 0;

  Future<void> pumpPage(WidgetTester tester) async {
    buttonPresses = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => KeyboardDismisser(child: child!),
        home: Scaffold(
          body: Column(
            children: [
              const TextField(
                key: Key('field'),
                keyboardType: TextInputType.number,
              ),
              ElevatedButton(
                onPressed: () => buttonPresses++,
                child: const Text('Button'),
              ),
              const Expanded(child: SizedBox(key: Key('blank'))),
            ],
          ),
        ),
      ),
    );
  }

  EditableText editable(WidgetTester tester) =>
      tester.widget<EditableText>(find.byType(EditableText));

  testWidgets('a tap on an empty area closes the keyboard', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.byKey(const Key('field')));
    await tester.pump();
    expect(editable(tester).focusNode.hasFocus, isTrue);

    await tester.tapAt(tester.getCenter(find.byKey(const Key('blank'))));
    await tester.pump();

    expect(editable(tester).focusNode.hasFocus, isFalse);
  });

  testWidgets('a tap on the field itself keeps it focused', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.byKey(const Key('field')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('field')));
    await tester.pump();

    expect(editable(tester).focusNode.hasFocus, isTrue);
  });

  testWidgets('buttons still receive their taps', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.byKey(const Key('field')));
    await tester.pump();

    await tester.tap(find.text('Button'));
    await tester.pump();

    expect(buttonPresses, 1);
  });

  testWidgets('a tap inside a dialog closes the keyboard', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => KeyboardDismisser(child: child!),
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const AlertDialog(
                title: Text('Title'),
                content: TextField(keyboardType: TextInputType.number),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(editable(tester).focusNode.hasFocus, isTrue);

    await tester.tap(find.text('Title'));
    await tester.pump();

    expect(editable(tester).focusNode.hasFocus, isFalse);
  });
}
