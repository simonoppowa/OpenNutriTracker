import 'package:intl/intl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/body_measurements/domain/body_length_unit.dart';

void main() {
  test('centimetres pass through', () {
    expect(BodyLengthUnit.cm.fromCm(84.5), 84.5);
    expect(BodyLengthUnit.cm.toCm(84.5), 84.5);
    expect(BodyLengthUnit.cm.format(84.0), '84');
    expect(BodyLengthUnit.cm.format(84.56), '84.6');
  });

  test('inches convert both ways', () {
    expect(BodyLengthUnit.inch.fromCm(2.54), closeTo(1, 1e-9));
    expect(BodyLengthUnit.inch.toCm(33), closeTo(83.82, 1e-9));
    expect(BodyLengthUnit.inch.format(83.82), '33');
  });

  test('the unit follows the height setting', () {
    expect(BodyLengthUnit.fromImperial(false), BodyLengthUnit.cm);
    expect(BodyLengthUnit.fromImperial(true), BodyLengthUnit.inch);
  });

  test('the allowed range in each unit', () {
    expect(BodyLengthUnit.cm.range, (min: 10, max: 300));
    expect(BodyLengthUnit.inch.range, (min: 4, max: 118));
  });

  test('decimals follow the locale', () {
    expect(Intl.withLocale('de', () => BodyLengthUnit.cm.format(84.5)), '84,5');
    expect(Intl.withLocale('en', () => BodyLengthUnit.cm.format(84.5)), '84.5');
  });
}
