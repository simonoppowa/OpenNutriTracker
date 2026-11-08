import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/sheet_bottom_inset.dart';

void main() {
  Future<double> insetFor(
    WidgetTester tester, {
    required double keyboard,
    required double navigationBar,
  }) async {
    late double inset;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          viewInsets: EdgeInsets.only(bottom: keyboard),
          viewPadding: EdgeInsets.only(bottom: navigationBar),
        ),
        child: Builder(
          builder: (context) {
            inset = sheetBottomInset(context);
            return const SizedBox();
          },
        ),
      ),
    );
    return inset;
  }

  testWidgets('clears the navigation bar while no keyboard is up', (
    tester,
  ) async {
    expect(await insetFor(tester, keyboard: 0, navigationBar: 48), 48);
  });

  testWidgets('clears the keyboard while it is up', (tester) async {
    expect(await insetFor(tester, keyboard: 300, navigationBar: 48), 300);
  });
}
