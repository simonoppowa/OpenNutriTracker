import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/presentation/widgets/copy_dialog.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/generated/l10n.dart';
import '../../../helpers/test_l10n.dart';

void main() {
  testWidgets('shows the initialValue as the dropdown selection on open',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.supportedLocales,
      home: const Scaffold(
        body: CopyDialog(initialValue: AddMealType.dinnerType),
      ),
    ));
    await tester.pumpAndSettle();

    final dropdown =
        tester.widget<DropdownButton<AddMealType>>(find.byType(DropdownButton<AddMealType>));
    expect(dropdown.value, AddMealType.dinnerType);
  });

  testWidgets('OK returns the initial value when nothing is changed',
      (tester) async {
    AddMealType? returned;
    late BuildContext capturedContext;

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: Builder(builder: (context) {
          capturedContext = context;
          return const SizedBox();
        }),
      ),
    ));
    await tester.pumpAndSettle();

    final future = showDialog<AddMealType>(
      context: capturedContext,
      builder: (_) => const CopyDialog(initialValue: AddMealType.lunchType),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();
    returned = await future;

    expect(returned, AddMealType.lunchType);
  });

  testWidgets('Cancel returns null even when initialValue is set',
      (tester) async {
    AddMealType? returned;
    late BuildContext capturedContext;

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: Builder(builder: (context) {
          capturedContext = context;
          return const SizedBox();
        }),
      ),
    ));
    await tester.pumpAndSettle();

    final future = showDialog<AddMealType>(
      context: capturedContext,
      builder: (_) => const CopyDialog(initialValue: AddMealType.snackType),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10nEn.dialogCancelLabel));
    await tester.pumpAndSettle();
    returned = await future;

    expect(returned, isNull);
  });

  testWidgets('user can change the selection and OK returns the new value',
      (tester) async {
    AddMealType? returned;
    late BuildContext capturedContext;

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: Builder(builder: (context) {
          capturedContext = context;
          return const SizedBox();
        }),
      ),
    ));
    await tester.pumpAndSettle();

    final future = showDialog<AddMealType>(
      context: capturedContext,
      builder: (_) =>
          const CopyDialog(initialValue: AddMealType.breakfastType),
    );
    await tester.pumpAndSettle();

    // Open the dropdown and pick "dinner".
    await tester.tap(find.byType(DropdownButton<AddMealType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.dinnerLabel).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();
    returned = await future;

    expect(returned, AddMealType.dinnerType);
  });
}
