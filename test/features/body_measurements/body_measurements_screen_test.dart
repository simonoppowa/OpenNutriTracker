import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/body_measurements/data/body_measurement_data_source.dart';
import 'package:opennutritracker/features/body_measurements/domain/body_length_unit.dart';
import 'package:opennutritracker/features/body_measurements/domain/body_measurement.dart';
import 'package:opennutritracker/features/body_measurements/domain/body_measurements_usecase.dart';
import 'package:opennutritracker/features/body_measurements/presentation/body_measurements_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../helpers/fake_hive_db_provider.dart';
import '../../helpers/test_l10n.dart';

/// In memory: Hive's file writes never finish inside a widget test's fake
/// async zone.
class _MemoryDataSource extends BodyMeasurementDataSource {
  final _byId = <String, BodyMeasurement>{};

  _MemoryDataSource() : super(FakeHiveDBProvider());

  @override
  List<BodyMeasurement> all() =>
      [..._byId.values]..sort((a, b) => b.date.compareTo(a.date));

  @override
  Future<void> put(BodyMeasurement measurement) async =>
      _byId[measurement.id] = measurement;

  @override
  Future<void> delete(String id) async => _byId.remove(id);
}

void main() {
  late BodyMeasurementsUsecase measurements;
  var ids = 0;

  setUp(() {
    ids = 0;
    measurements = BodyMeasurementsUsecase(
      _MemoryDataSource(),
      newId: () => 'm${++ids}',
    );
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    BodyLengthUnit unit = BodyLengthUnit.cm,
  }) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: BodyMeasurementsScreen(usecase: measurements, unit: unit),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder field(String kind) => find.descendant(
    of: find.bySemanticsIdentifier('body-measurement-$kind'),
    matching: find.byType(TextField),
  );

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(find.bySemanticsIdentifier('body-measurement-save'));
    await tester.pumpAndSettle();
  }

  testWidgets('an empty list explains what to do', (tester) async {
    await pumpScreen(tester);

    expect(find.text(l10nEn.bodyMeasurementsEmpty), findsOneWidget);
  });

  testWidgets('a measurement is recorded with the given measures', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.bySemanticsIdentifier('body-measurement-add'));
    await tester.pumpAndSettle();
    await tester.enterText(field('waist'), '84,5');
    await tester.enterText(field('hip'), '99');
    await tapSave(tester);

    final saved = measurements.list().single;
    expect(saved[BodyMeasureKind.waist], 84.5);
    expect(saved[BodyMeasureKind.hip], 99);
    expect(saved[BodyMeasureKind.chest], isNull);
    expect(find.textContaining('Waist 84.5 cm'), findsOneWidget);
  });

  testWidgets('a measurement without any measure is refused', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.bySemanticsIdentifier('body-measurement-add'));
    await tester.pumpAndSettle();
    await tapSave(tester);

    expect(find.text(l10nEn.bodyMeasurementNeedOne), findsOneWidget);
    expect(measurements.list(), isEmpty);
  });

  testWidgets('a value out of range is refused', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.bySemanticsIdentifier('body-measurement-add'));
    await tester.pumpAndSettle();
    await tester.enterText(field('arm'), '3');
    await tapSave(tester);

    expect(find.text(l10nEn.bodyMeasurementRange(10, 300, 'cm')), findsOne);
  });

  testWidgets('inches are entered and stored as centimetres', (tester) async {
    await pumpScreen(tester, unit: BodyLengthUnit.inch);

    await tester.tap(find.bySemanticsIdentifier('body-measurement-add'));
    await tester.pumpAndSettle();
    await tester.enterText(field('waist'), '33');
    await tapSave(tester);

    expect(
      measurements.list().single[BodyMeasureKind.waist],
      closeTo(83.82, 1e-9),
    );
    expect(find.textContaining('Waist 33 in'), findsOneWidget);
  });

  testWidgets('a measurement is edited and deleted', (tester) async {
    await measurements.add(
      date: DateTime(2026, 10, 1),
      valuesCm: {BodyMeasureKind.waist: 85},
    );
    await pumpScreen(tester);

    await tester.tap(find.textContaining('Waist 85 cm'));
    await tester.pumpAndSettle();
    await tester.enterText(field('waist'), '84');
    await tapSave(tester);
    expect(measurements.list().single[BodyMeasureKind.waist], 84);
    expect(measurements.list().single.id, 'm1');

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.dialogDeleteLabel).last);
    await tester.pumpAndSettle();

    expect(measurements.list(), isEmpty);
  });

  testWidgets('the chart follows the chosen measure', (tester) async {
    await measurements.add(
      date: DateTime(2026, 9, 1),
      valuesCm: {BodyMeasureKind.waist: 88, BodyMeasureKind.hip: 100},
    );
    await measurements.add(
      date: DateTime(2026, 10, 1),
      valuesCm: {BodyMeasureKind.waist: 85},
    );
    await pumpScreen(tester);

    expect(find.byKey(const Key('bodyMeasurementChart')), findsOneWidget);
    await tester.tap(find.bySemanticsIdentifier('body-measurement-chart-hip'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bodyMeasurementChart')), findsNothing);
    expect(find.text(l10nEn.bodyMeasurementsChartEmpty), findsOneWidget);
  });
}
