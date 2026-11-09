import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/log_tray.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/log_tray_widgets.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/test_l10n.dart';

MealEntity _meal(String name, double kcal100) => MealEntity(
  code: name,
  name: name,
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: 'g',
  servingSize: null,
  nutriments: MealNutrimentsEntity(
    energyKcal100: kcal100,
    carbohydrates100: 10,
    fat100: 5,
    proteins100: 3,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  source: MealSourceEntity.custom,
);

/// [kcal] of a 100 kcal/100 g food, as one row: the grams are the kcal.
LogTrayItem _item(String name, double kcal) => LogTrayItem(
  meal: _meal(name, 100),
  unit: 'g',
  amount: kcal,
  amountLabel: '$kcal g',
);

Future<void> _pumpTray(
  WidgetTester tester,
  LogTray tray, {
  bool kilojoules = false,
  ValueChanged<LogTrayItem>? onEdit,
}) => tester.pumpWidget(
  ChangeNotifierProvider(
    create: (_) => EnergyUnitProvider(usesKilojoules: kilojoules),
    child: MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: ListView(
          children: [
            LogTrayList(tray: tray, onEdit: onEdit),
            LogTrayLogButton(tray: tray, onPressed: () {}),
          ],
        ),
      ),
    ),
  ),
);

void main() {
  group('the To-log rows add up to the total under them (#1469)', () {
    testWidgets('the 2.6.0 case: 80.85 + 14.7 reads 81 + 15 = 96', (
      tester,
    ) async {
      final tray = LogTray()
        ..add(_item('Nutella', 80.85))
        ..add(_item('Apple', 14.7));
      await _pumpTray(tester, tray);

      expect(find.text('80.85 g · 81 kcal'), findsOneWidget);
      expect(find.text('14.7 g · 15 kcal'), findsOneWidget);
      expect(find.text('96 kcal'), findsOneWidget);
    });

    testWidgets('the total is the sum of the rows as shown', (tester) async {
      // 94.8 kcal exactly, but the rows read 80 and 14.
      final tray = LogTray()
        ..add(_item('A', 80.4))
        ..add(_item('B', 14.4));
      await _pumpTray(tester, tray);

      expect(find.text('80.4 g · 80 kcal'), findsOneWidget);
      expect(find.text('14.4 g · 14 kcal'), findsOneWidget);
      expect(find.text('94 kcal'), findsOneWidget);
    });

    testWidgets('in kJ too', (tester) async {
      final tray = LogTray()
        ..add(_item('A', 80.4))
        ..add(_item('B', 14.4));
      await _pumpTray(tester, tray, kilojoules: true);

      expect(find.text('80.4 g · 336 kJ'), findsOneWidget);
      expect(find.text('14.4 g · 60 kJ'), findsOneWidget);
      expect(find.text('396 kJ'), findsOneWidget);
    });
  });

  group('changing a row\'s amount', () {
    testWidgets('a row with an amount is a button that says what it does', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final editable = LogTrayItem(
        meal: _meal('Oats', 380),
        unit: 'g',
        amount: 50,
        amountLabel: '50 g',
        quantity: 50,
        selectedUnit: 'g',
      );
      LogTrayItem? opened;
      final tray = LogTray()
        ..add(editable)
        ..add(_item('Quick', 100));
      await _pumpTray(tester, tray, onEdit: (item) => opened = item);

      final rows = find.bySemanticsIdentifier('add-meal-tray-edit');
      // The Quick add-style row (no quantity) is not offered.
      expect(rows, findsOneWidget);
      expect(
        tester.getSemantics(rows),
        isSemantics(
          hasTapAction: true,
          onTapHint: l10nEn.logTrayEditAmountLabel,
        ),
      );
      await tester.tap(rows);
      expect(opened, same(editable));
      handle.dispose();
    });
  });
}
