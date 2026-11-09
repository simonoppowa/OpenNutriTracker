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

const _wcagAa = 4.5;

String _hex(Color c) => '0x${c.toARGB32().toRadixString(16).toUpperCase()}';

/// `secondary` and `tertiary` are painted as small text: the bulk-add
/// "uncertain" and "check amount" labels (tertiary) and the export dialog's
/// CSV note (secondary). They sit on the canvas, a card or a muted fill, so
/// each must clear AA on all three.
void _expectTextRolesReadable(AppPalette palette, String label) {
  final scheme = palette.colorScheme;
  final roles = {'secondary': scheme.secondary, 'tertiary': scheme.tertiary};
  final backgrounds = {
    'canvas': palette.canvas,
    'surface': palette.surface,
    'surfaceMuted': palette.surfaceMuted,
  };
  for (final role in roles.entries) {
    for (final bg in backgrounds.entries) {
      final ratio = _contrast(role.value, bg.value);
      expect(
        ratio,
        greaterThanOrEqualTo(_wcagAa),
        reason:
            '$label: ${role.key} ${_hex(role.value)} on ${bg.key} '
            '${_hex(bg.value)} is ${ratio.toStringAsFixed(2)}:1, below AA',
      );
    }
  }
}

void main() {
  group('AppPalette.colorScheme secondary/tertiary text contrast', () {
    for (final base in [AppPalette.light, AppPalette.dark]) {
      final mode = base.brightness.name;

      test('default palette meets WCAG AA ($mode)', () {
        _expectTextRolesReadable(base, '$mode default');
      });

      // The roles follow the fixed macro colours, not the accent, so a custom
      // accent must leave them readable too.
      test('every accent preset keeps them at WCAG AA ($mode)', () {
        for (final accent in accentPresetColors) {
          _expectTextRolesReadable(
            base.withAccent(accent),
            '$mode accent ${_hex(accent)}',
          );
        }
      });
    }

    test('the macro colours themselves stay unchanged', () {
      expect(AppPalette.light.proteinColor, const Color(0xFF1F8E80));
      expect(AppPalette.light.carbsColor, const Color(0xFFB87410));
    });
  });
}
