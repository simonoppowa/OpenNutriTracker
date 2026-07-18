import 'dart:math';

import 'package:flutter/material.dart';
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
      // double.parse() accepts the literal strings "NaN"/"Infinity"/
      // "-Infinity" and otherwise throws on garbage input. Upstream food
      // APIs (notably Open Food Facts) occasionally carry exactly that kind
      // of malformed nutriment value, which would otherwise silently poison
      // downstream macro calculations (e.g. NaN.toInt() throwing in the
      // diary's macro rings).
      value = double.tryParse(stringValue);
      if (value != null && !value.isFinite) value = null;
    } else {
      value = null;
    }

    return value;
  }
}

extension CastString on String {
  String? toStringOrNull() {
    if (isEmpty) {
      return null;
    } else {
      return this;
    }
  }

  double? toDoubleOrNull() {
    if (isEmpty) {
      return null;
    } else {
      final value = double.tryParse(this);
      return (value != null && value.isFinite) ? value : null;
    }
  }
}

extension Round on double {
  double roundToPrecision(int n) {
    int fac = pow(10, n).toInt();
    return (this * fac).round() / fac;
  }
}

extension DisplayDouble on double? {
  String toStringOrEmpty() {
    if (this == null) {
      return "";
    } else {
      return toString();
    }
  }
}

extension FormatString on DateTime {
  String toParsedDay() => DateFormat('yyyy-MM-dd').format(this);
}

extension ColorExtension on Color {
  /// Converts the color to a hexadecimal string.
  String toHex() {
    final red = (r * 255).toInt().toRadixString(16).padLeft(2, '0');
    final green = (g * 255).toInt().toRadixString(16).padLeft(2, '0');
    final blue = (b * 255).toInt().toRadixString(16).padLeft(2, '0');

    return '#'
            '$red$green$blue'
        .toUpperCase();
  }
}
