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
const _dark = Color(0xFF20201C);
const _wcagAa = 4.5;

String _hex(Color c) => '0x${c.toARGB32().toRadixString(16).toUpperCase()}';

void _expectReadable(AppPalette base, Color accent) {
  final palette = base.withAccent(accent);
  final chosen = _contrast(palette.onAccent, accent);
  final best = math.max(_contrast(_white, accent), _contrast(_dark, accent));
  expect(
    palette.onAccent == _white || palette.onAccent == _dark,
    isTrue,
    reason: 'onAccent for ${_hex(accent)} must be white or the dark ink',
  );
  if (best >= _wcagAa) {
    expect(
      chosen,
      greaterThanOrEqualTo(_wcagAa),
      reason:
          'onAccent ${_hex(palette.onAccent)} on ${_hex(accent)} is '
          '${chosen.toStringAsFixed(2)}:1, below WCAG AA',
    );
  } else {
    expect(
      chosen,
      best,
      reason:
          'neither option reaches AA on ${_hex(accent)}; '
          'onAccent must be the higher-contrast one',
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

      // Material You hands withAccent an arbitrary harmonized primary, so
      // sweep the RGB cube instead of trusting the sixteen presets alone.
      test('arbitrary accents get the higher-contrast text colour ($mode)', () {
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
