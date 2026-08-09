import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

/// The placeholder in the bulk-add text field is instructional — it is the
/// only place the syntax is explained, so a hint the parser cannot read
/// teaches the user a format that produces nothing.
///
/// Two shipped hints did exactly that: the Ukrainian one used a Cyrillic
/// "г" (U+0433) rather than a Latin "g", and the Chinese one used 克 for
/// gram and 、 as the separator. Neither is a unit symbol or a separator
/// the parser recognises, so `100г тост` kept its digits in the food name
/// and the whole Chinese hint collapsed to a single unparsed item.
///
/// This reads the ARBs off disk rather than through the generated
/// localizations so it covers every locale without needing a widget test.
void main() {
  final arbDir = Directory('lib/l10n');

  test('every locale hint parses into three items', () {
    final files = arbDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.arb'))
        .toList();

    expect(files, isNotEmpty, reason: 'no ARB files found');

    for (final file in files) {
      final locale = file.uri.pathSegments.last;
      final hint =
          (jsonDecode(file.readAsStringSync()) as Map)['bulkAddInputHint']
              as String?;
      expect(hint, isNotNull, reason: '$locale is missing bulkAddInputHint');

      final result = parseMealText(hint!);

      expect(
        result.errors,
        isEmpty,
        reason: '$locale hint "$hint" produced parse errors',
      );
      expect(
        result.items,
        hasLength(3),
        reason:
            '$locale hint "$hint" parsed into ${result.items.length} items, '
            'but it depicts three',
      );

      // At least two of the three must carry a quantity — the hint exists
      // to demonstrate that amounts are understood. A hint where every
      // amount is silently dropped looks like it works but teaches nothing.
      final withQuantity = result.items.where((i) => i.quantity != null);
      expect(
        withQuantity,
        hasLength(greaterThanOrEqualTo(2)),
        reason:
            '$locale hint "$hint" only had ${withQuantity.length} item(s) '
            'with a recognised quantity',
      );

      // Digits left in a food name mean the amount was not understood and
      // will be sent to the food search as part of the query.
      for (final item in result.items) {
        expect(
          RegExp(r'\d').hasMatch(item.query),
          isFalse,
          reason:
              '$locale hint "$hint" left digits in the query "${item.query}" '
              '— the amount was not recognised',
        );
      }
    }
  });
}
