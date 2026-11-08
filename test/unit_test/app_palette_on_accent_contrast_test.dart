import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/styles/accent_colors.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';

/// WCAG 2.x contrast ratio, computed here rather than borrowed from the code
/// under test so the test checks the formula, not itself.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

const _white = Color(0xFFFFFFFF);
const _ink = Color(0xFF20201C);
const _black = Color(0xFF000000);
const _wcagAa = 4.5;

String _hex(Color c) => '0x${c.toARGB32().toRadixString(16).toUpperCase()}';

void _expectReadable(AppPalette base, Color accent) {
  final onAccent = base.withAccent(accent).onAccent;
  final chosen = _contrast(onAccent, accent);
  expect(
    chosen,
    greaterThanOrEqualTo(_wcagAa),
    reason:
        'onAccent ${_hex(onAccent)} on ${_hex(accent)} is '
        '${chosen.toStringAsFixed(2)}:1, below WCAG AA',
  );

  // The warm ink is preferred; black only stands in when neither white nor
  // the ink reaches AA.
  final white = _contrast(_white, accent);
  final ink = _contrast(_ink, accent);
  final warmReachesAa = math.max(white, ink) >= _wcagAa;
  if (warmReachesAa) {
    expect(
      onAccent,
      white >= ink ? _white : _ink,
      reason: 'on ${_hex(accent)} pick the higher of white and the ink',
    );
  } else {
    expect(
      onAccent,
      isNot(_ink),
      reason: 'the ink misses AA on ${_hex(accent)}; use white or black',
    );
  }
}

void main() {
  group('AppPalette.withAccent onAccent contrast', () {
    for (final base in [AppPalette.light, AppPalette.dark]) {
      final mode = base.brightness.name;

      test('every accent preset meets WCAG AA ($mode)', () {
        for (final accent in accentPresetColors) {
          _expectReadable(base, accent);
        }
      });

      test('black replaces the ink only where both miss AA ($mode)', () {
        const red = Color(0xFFE53935);
        const teal = Color(0xFF00897B);
        const blue = Color(0xFF1E88E5);
        const pink = Color(0xFFEC407A);
        const cyan = Color(0xFF00ACC1);
        const yellow = Color(0xFFFDD835);
        for (final accent in [red, teal, blue, pink]) {
          expect(base.withAccent(accent).onAccent, _black);
        }
        expect(base.withAccent(cyan).onAccent, _ink);
        expect(base.withAccent(yellow).onAccent, _ink);
      });

      // Material You hands withAccent an arbitrary harmonized primary, so
      // sweep the RGB cube instead of trusting the sixteen presets alone.
      test('arbitrary accents meet WCAG AA ($mode)', () {
        for (var r = 0; r <= 0xFF; r += 0x11) {
          for (var g = 0; g <= 0xFF; g += 0x11) {
            for (var b = 0; b <= 0xFF; b += 0x11) {
              _expectReadable(base, Color.fromARGB(0xFF, r, g, b));
            }
          }
        }
      });
    }

    test('hand-tuned default palettes keep their onAccent', () {
      expect(AppPalette.light.onAccent, const Color(0xFFFFFFFF));
      expect(AppPalette.dark.onAccent, const Color(0xFF06281A));
    });
  });
}
