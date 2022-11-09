import 'dart:math';

import 'package:intl/intl.dart';

extension Round on double {
  double roundToPrecision(int n) {
    int fac = pow(10, n).toInt();
    return (this * fac).round() / fac;
  }
}

extension FormatString on DateTime {
  String toParsedDay() => DateFormat.yMd().format(this);
}
