import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/physical_activity_dbo.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/activity_card.dart';
import 'package:opennutritracker/core/utils/csv_data_exporter.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../fixture/physical_activity_entity_fixtures.dart';
import '../helpers/test_l10n.dart';

/// #512: the name typed on the Custom activity screen has to reach the
/// logged entry, not only the optional template.
void main() {
  group('PhysicalActivityEntity.withCustomName', () {
    test('a typed name becomes the Custom activity label', () {
      final named = PhysicalActivityEntity.custom.withCustomName(
        'Evening ride',
      );

      expect(named.isCustom, isTrue);
      expect(named.specificActivity, 'Evening ride');
      expect(named.mets, PhysicalActivityEntity.custom.mets);
      expect(named.type, PhysicalActivityEntity.custom.type);
    });

    test('surrounding whitespace is trimmed', () {
      final named = PhysicalActivityEntity.custom.withCustomName(
        '  Evening ride \n',
      );

      expect(named.specificActivity, 'Evening ride');
    });

    test('an empty, whitespace-only or missing name keeps the entity', () {
      for (final name in [null, '', '   ', '\t\n']) {
        expect(
          PhysicalActivityEntity.custom.withCustomName(name),
          same(PhysicalActivityEntity.custom),
          reason: 'name: ${jsonEncode(name)}',
        );
      }
    });

    test('an already-named entity keeps its name when none is typed', () {
      // Re-logging a named entry from Recents opens the screen with an
      // empty name field; the entry keeps the name it was listed under.
      final fromRecents = PhysicalActivityEntity.customNamed('Evening ride');

      expect(fromRecents.withCustomName('  ').specificActivity, 'Evening ride');
      expect(fromRecents.withCustomName('Commute').specificActivity, 'Commute');
    });

    test('a compendium activity ignores the name', () {
      const running = PhysicalActivityFixtures.vigorousRunning;

      expect(running.withCustomName('My run'), same(running));
    });
  });

  group('display', () {
    Future<BuildContext> pumpContext(WidgetTester tester) async {
      late BuildContext captured;
      await tester.pumpWidget(
        ChangeNotifierProvider<EnergyUnitProvider>(
          create: (_) => EnergyUnitProvider(),
          child: MaterialApp(
            localizationsDelegates: const [S.delegate],
            supportedLocales: S.supportedLocales,
            home: Builder(
              builder: (context) {
                captured = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return captured;
    }

    testWidgets('a named Custom activity shows its name', (tester) async {
      final context = await pumpContext(tester);

      expect(
        PhysicalActivityEntity.custom
            .withCustomName('Evening ride')
            .getName(context),
        'Evening ride',
      );
    });

    testWidgets('an unnamed Custom activity keeps the generic label', (
      tester,
    ) async {
      final context = await pumpContext(tester);

      expect(
        PhysicalActivityEntity.custom.withCustomName('   ').getName(context),
        l10nEn.customActivityName,
      );
    });

    testWidgets('an entry saved before the fix still reads as Custom', (
      tester,
    ) async {
      // What the screen stored before #512: the plain sentinel, whose
      // specificActivity is the literal 'custom'.
      final context = await pumpContext(tester);
      final stored = PhysicalActivityDBO(
        PhysicalActivityEntity.customCode,
        'custom',
        'user-entered kcal',
        0.0,
        const [],
        PhysicalActivityTypeDBO.conditioningExercise,
      );

      expect(
        PhysicalActivityEntity.fromPhysicalActivityDBO(stored).getName(context),
        l10nEn.customActivityName,
      );
    });

    testWidgets('a very long name stays on one line in the diary row', (
      tester,
    ) async {
      final longName = 'Evening bike commute through the park ' * 6;
      final activity = UserActivityEntity(
        'act-long',
        0,
        250,
        DateTime(2026, 11, 9),
        PhysicalActivityEntity.custom.withCustomName(longName),
        userKcal: 250,
      );
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ChangeNotifierProvider<EnergyUnitProvider>(
          create: (_) => EnergyUnitProvider(),
          child: MaterialApp(
            localizationsDelegates: const [S.delegate],
            supportedLocales: S.supportedLocales,
            home: Scaffold(
              body: ActivityCard(
                activityEntity: activity,
                onItemLongPressed: (_, _) {},
                firstListElement: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final title = tester.widget<Text>(
        find.textContaining('Evening bike commute'),
      );
      expect(title.maxLines, 1);
      expect(title.overflow, TextOverflow.ellipsis);
    });
  });

  group('export / import', () {
    UserActivityDBO namedDbo(String name) =>
        UserActivityDBO.fromUserActivityEntity(
          UserActivityEntity(
            'act-named',
            0,
            320,
            DateTime.utc(2026, 11, 9, 18),
            PhysicalActivityEntity.custom.withCustomName(name),
            userKcal: 320,
          ),
        );

    test('the name survives a JSON backup round trip', () {
      final dbo = namedDbo('Ride, "hilly" route');

      final restored = UserActivityDBO.fromJson(
        jsonDecode(jsonEncode(dbo.toJson())) as Map<String, dynamic>,
      );
      final entity = UserActivityEntity.fromUserActivityDBO(restored);

      expect(entity.physicalActivityEntity.isCustom, isTrue);
      expect(
        entity.physicalActivityEntity.specificActivity,
        'Ride, "hilly" route',
      );
      expect(entity.userKcal, 320);
    });

    test('the name survives a CSV export round trip', () {
      final dbo = namedDbo('Ride, "hilly" route');

      final parsed = CsvDataExporter.parseUserActivitiesFromCsv(
        CsvDataExporter.userActivitiesToCsv([dbo]),
      ).single;

      expect(
        parsed.physicalActivityDBO.code,
        PhysicalActivityEntity.customCode,
      );
      expect(
        parsed.physicalActivityDBO.specificActivity,
        'Ride, "hilly" route',
      );
      expect(parsed.userKcal, 320);
    });
  });
}
