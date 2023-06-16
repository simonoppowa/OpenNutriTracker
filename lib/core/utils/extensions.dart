import 'dart:math';

import 'package:intl/intl.dart';

extension Cast on Object? {
  double? asDoubleOrNull() {
    double? value;
    if (this is int) {
      final intValue = this as int;
      value = intValue.toDouble();
    } else if (this is double) {
      value = this as double;
    } else if (this is String) {
      final stringValue = this as String;
      value = double.parse(stringValue);
    } else {
      value = null;
    }

    return value;
  }
}

extension Round on double {
  double roundToPrecision(int n) {
    int fac = pow(10, n).toInt();
    return (this * fac).round() / fac;
  }
}

extension FormatString on DateTime {
  String toParsedDay() => DateFormat.yMd().format(this);
}
