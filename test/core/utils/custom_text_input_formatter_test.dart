import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/custom_text_input_formatter.dart';

void main() {
  /// What the field holds after [typed] replaces [old], run through every
  /// formatter `doubleOnly` returns, in order.
  String type(String old, String typed) {
    var value = TextEditingValue(text: typed);
    for (final formatter in CustomTextInputFormatter.doubleOnly()) {
      value = formatter.formatEditUpdate(TextEditingValue(text: old), value);
    }
    return value.text;
  }

  group('CustomTextInputFormatter.doubleOnly', () {
    test('drops a minus, a letter or a second separator', () {
      expect(type('120', '120-'), '120');
      expect(type('120', '-120'), '120');
      expect(type('12', '12a'), '12');
      expect(type('1.5', '1.5.'), '1.5');
      expect(type('1.5', '1.5,'), '1.5');
    });

    test('still takes digits, a comma or a period', () {
      expect(type('12', '120'), '120');
      expect(type('1', '1,'), '1.');
      expect(type('', '.5'), '.5');
      expect(type('1.25', ''), '');
    });

    test('still drops a third decimal', () {
      expect(type('1.25', '1.255'), '1.25');
    });
  });
}
