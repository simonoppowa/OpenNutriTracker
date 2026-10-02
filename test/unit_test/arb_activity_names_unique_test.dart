import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/physical_activity_data_source.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

/// No two activities may share an English name.
///
/// #1200: `paDivingSpringboardPlatform` read "diving", the same as
/// `paDivingGeneral` (3.0 vs 7.0 MET), and `paAmericanFootballGeneral` read
/// "football", which most languages render as soccer — a separate activity.
/// A translator carried both faithfully and the picker showed two identical
/// rows that burn very different calories. Four more pairs (boxing, martial
/// arts, rugby, high intensity interval exercise) had the same shape.
///
/// The picker shows the description under the name, but the home and diary
/// cards and the collapsed detail-screen title show the name alone — so the
/// name has to carry the distinction on its own. The source is checked, not
/// the translations: a code PR edits `intl_en.arb` only. A *new* key shows
/// its English text in every language until Weblate fills it; a *renamed*
/// key does not — Weblate flags the unit "needs editing" and the shipped ARB
/// keeps the old translation until a translator acts, so `de` still showed
/// "Tauchen" twice two days after #1201 landed. Nothing here can fix that;
/// it can only make sure the source is right.
///
/// Two views of the same property, because each misses what the other sees:
///
/// * The ARB view groups the `pa*` name keys by value. It is what #1200
///   asked for, and it needs no widget tree.
/// * The rendered view walks every data-source row through `getName` in an
///   English `MaterialApp`. The ARB view cannot see a collision that lives in
///   the code→key map — two rows wired to one key (18355 "water aerobics"
///   was wired to `paWaterAerobics`, the same key as 02120 "water exercise",
///   while its own `paWateraerobicsCalisthenics` sat translated and unused;
///   15732–15734 shared `paTrackField`), or a row with no entry at all, which
///   falls back to its section heading and so rendered six conditioning rows,
///   yoga among them, as "conditioning exercise / conditioning exercise".
///
/// `paHeading*` keys are section titles ("bicycling" above the bicycling
/// rows), not activities, and are excluded from the ARB view on purpose. In
/// the rendered view a general row may equal its heading ("bicycling",
/// "running") — that is one row, not two — so the unmapped-row check looks
/// for the fallback on *both* name and description, which no mapped row has.
void main() {
  final source = File('lib/l10n/intl_en.arb');
  final activityName = RegExp(r'^pa[A-Z]\w*$');

  Map<String, String> activityNames() {
    final messages =
        jsonDecode(source.readAsStringSync()) as Map<String, dynamic>;
    return {
      for (final entry in messages.entries)
        if (entry.value is String &&
            activityName.hasMatch(entry.key) &&
            !entry.key.endsWith('Desc') &&
            !entry.key.startsWith('paHeading'))
          entry.key: entry.value as String,
    };
  }

  String collisions(Map<String, List<String>> byName) => [
    for (final entry in byName.entries)
      if (entry.value.length > 1) '"${entry.key}": ${entry.value.join(', ')}',
  ].join('\n');

  test('the scan actually reaches the activity names', () {
    final names = activityNames();
    expect(names.length, greaterThanOrEqualTo(100), reason: 'found: $names');
    expect(names, contains('paDivingSpringboardPlatform'));
    expect(names, isNot(contains('paDivingSpringboardPlatformDesc')));
    expect(names, isNot(contains('paHeadingBicycling')));
  });

  test('no two activity keys share an English name', () {
    final byName = <String, List<String>>{};
    for (final entry in activityNames().entries) {
      byName
          .putIfAbsent(entry.value.trim().toLowerCase(), () => [])
          .add(entry.key);
    }
    expect(collisions(byName), isEmpty);
  });

  group('rendered in English', () {
    late BuildContext context;
    late List<PhysicalActivityEntity> rows;

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        // getDescription builds its whole map eagerly, and the Custom
        // activity's entry reads the energy unit off the provider.
        ChangeNotifierProvider(
          create: (_) => EnergyUnitProvider(),
          child: MaterialApp(
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.supportedLocales,
            locale: const Locale('en'),
            home: Builder(
              builder: (c) {
                context = c;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      rows = PhysicalActivityDataSource()
          .getPhysicalActivityList()
          .map(PhysicalActivityEntity.fromPhysicalActivityDBO)
          .toList();
      expect(rows.length, greaterThanOrEqualTo(100));
    }

    testWidgets('no two activity rows render the same name', (tester) async {
      await pump(tester);
      final byName = <String, List<String>>{};
      for (final row in rows) {
        byName
            .putIfAbsent(row.getName(context).trim().toLowerCase(), () => [])
            .add('${row.code} (${row.mets} MET)');
      }
      expect(collisions(byName), isEmpty);
    });

    testWidgets('every activity row has a name of its own', (tester) async {
      await pump(tester);
      // Read the maps, not the rendered string: a row with no getName entry
      // renders its section heading, but so does a legitimately named
      // "general" row ("bicycling, general" renders "bicycling"), and a row
      // can lose its name entry while keeping its description.
      final names = PhysicalActivityEntity.nameByCode(context);
      final descriptions = PhysicalActivityEntity.descriptionByCode(context);
      final unnamed = [
        for (final row in rows)
          if (!names.containsKey(row.code)) '${row.code} ${row.specificActivity}',
      ];
      expect(unnamed, isEmpty, reason: 'no getName entry — renders the heading');
      final undescribed = [
        for (final row in rows)
          if (!descriptions.containsKey(row.code))
            '${row.code} ${row.specificActivity}',
      ];
      expect(undescribed, isEmpty, reason: 'no getDescription entry');
    });
  });
}
