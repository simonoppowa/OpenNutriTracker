import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/custom_text_input_formatter.dart';

TextEditingValue _value(String text) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: text.length),
);

TextEditingValue _edit(
  TextEditingValue oldValue,
  TextEditingValue newValue, {
  int maxDecimals = 2,
}) => CustomTextInputFormatter.doubleOnly(maxDecimals: maxDecimals).fold(
  newValue,
  (value, formatter) => formatter.formatEditUpdate(oldValue, value),
);

void main() {
  test(
    'loaded precision can be reduced, replaced, or cleared without freezing',
    () {
      var value = _value('28.3495');
      for (final text in [
        '28.349',
        '28.348',
        '128.348',
        '128.34',
        '',
        '3',
        '30',
      ]) {
        value = _edit(value, _value(text));
        expect(value, _value(text));
      }
    },
  );

  test('new entry retains its configured fractional limit', () {
    for (final limit in [1, 2]) {
      final oldValue = _value(limit == 1 ? '28.3' : '28.34');
      expect(
        _edit(oldValue, _value('${oldValue.text}5'), maxDecimals: limit),
        oldValue,
      );
      expect(
        _edit(_value(''), _value('28.3495'), maxDecimals: limit),
        _value(''),
      );
    }
    final oldValue = _value('28.3495');
    expect(_edit(oldValue, _value('28.34956')), oldValue);
    // Reducing precision does not leave a permanently raised limit.
    expect(_edit(_value('28.34'), _value('28.349')), _value('28.34'));
  });

  test('overprecision exception accepts only decimal numbers', () {
    final oldValue = _value('28.3495');
    for (final text in [
      'a28.349',
      '28..34',
      '28.34e2',
      'NaN.123',
      'Infinity.123',
    ]) {
      expect(_edit(oldValue, _value(text)), oldValue);
    }
  });

  test('comma normalization preserves selection and composing ranges', () {
    final proposed = TextEditingValue(
      text: '28,349',
      selection: const TextSelection(baseOffset: 1, extentOffset: 5),
      composing: const TextRange(start: 0, end: 6),
    );
    expect(
      _edit(_value('28.3495'), proposed),
      proposed.copyWith(text: '28.349'),
    );
    expect(_edit(_value(''), _value('1,2')), _value('1.2'));
    expect(_edit(_value('28,3495'), _value('28,349')), _value('28.349'));
  });
}
