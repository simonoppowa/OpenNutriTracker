import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/energy_display.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

/// Builds a tree in the given unit and returns what [read] produced in it.
Future<T> _inUnit<T>(
  WidgetTester tester, {
  required bool kilojoules,
  required T Function(BuildContext context) read,
}) async {
  late T result;
  await tester.pumpWidget(
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
        home: Builder(
          builder: (context) {
            result = read(context);
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  return result;
}

void main() {
  group('EnergyDisplay rounds to nearest (#1469)', () {
    testWidgets('kcal values round instead of truncating', (tester) async {
      final values = await _inUnit(
        tester,
        kilojoules: false,
        read: (context) => [
          for (final kcal in [80.85, 14.7, 1839.8, 80.4, 0.0, 0.5])
            EnergyDisplay.formatValue(context, kcal),
        ],
      );
      expect(values, ['81', '15', '1840', '80', '0', '1']);
    });

    testWidgets('kJ rounds after converting, not before', (tester) async {
      final values = await _inUnit(
        tester,
        kilojoules: true,
        read: (context) => [
          // 14.7 kcal = 61.5 kJ; 80.85 kcal = 338.3 kJ.
          EnergyDisplay.formatWithUnit(context, 14.7),
          EnergyDisplay.formatWithUnit(context, 80.85),
        ],
      );
      expect(values, ['62 kJ', '338 kJ']);
    });

    testWidgets('formatWithUnit appends the kcal label', (tester) async {
      final value = await _inUnit(
        tester,
        kilojoules: false,
        read: (context) => EnergyDisplay.formatWithUnit(context, 80.85),
      );
      expect(value, '81 kcal');
    });
  });

  group('EnergyDisplay.formatSumWithUnit', () {
    testWidgets('totals the rounded rows, not the exact sum', (tester) async {
      // 80.4 + 14.4 = 94.8, which alone would read 95; the rows read
      // 80 and 14.
      final value = await _inUnit(
        tester,
        kilojoules: false,
        read: (context) =>
            EnergyDisplay.formatSumWithUnit(context, [80.4, 14.4]),
      );
      expect(value, '94 kcal');
    });

    testWidgets('in kJ it totals the rows as converted and rounded', (
      tester,
    ) async {
      // The rows read 336 kJ and 60 kJ; converting the kcal sum would
      // read 397 kJ.
      final value = await _inUnit(
        tester,
        kilojoules: true,
        read: (context) =>
            EnergyDisplay.formatSumWithUnit(context, [80.4, 14.4]),
      );
      expect(value, '396 kJ');
    });

    testWidgets('an empty list totals zero', (tester) async {
      final value = await _inUnit(
        tester,
        kilojoules: false,
        read: (context) => EnergyDisplay.formatSumWithUnit(context, const []),
      );
      expect(value, '0 kcal');
    });
  });
}
