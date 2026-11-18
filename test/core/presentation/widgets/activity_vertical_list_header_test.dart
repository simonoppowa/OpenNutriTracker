import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/activity_vertial_list.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../fixture/physical_activity_entity_fixtures.dart';
import '../../../helpers/test_l10n.dart';

// Two activities whose cards read 🔥300 kcal and 🔥150.5 kcal.
final _activities = [
  UserActivityEntity(
    'a1',
    60,
    300,
    DateTime(2026, 1, 1),
    PhysicalActivityFixtures.moderateBicycling,
  ),
  UserActivityEntity(
    'a2',
    30,
    150.5,
    DateTime(2026, 1, 1),
    PhysicalActivityFixtures.lightDancing,
  ),
];

Widget _list(
  List<UserActivityEntity> activities, {
  bool usesKilojoules = false,
}) {
  return ChangeNotifierProvider<EnergyUnitProvider>(
    create: (_) => EnergyUnitProvider(usesKilojoules: usesKilojoules),
    child: MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ActivityVerticalList(
            day: DateTime(2026, 1, 1),
            title: 'Activity',
            userActivityList: activities,
            onItemLongPressedCallback: (_, _) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('ActivityVerticalList header total (#1299)', () {
    testWidgets('shows the summed burned energy in kcal', (tester) async {
      await tester.pumpWidget(_list(_activities));
      await tester.pump();

      // 300 + 150.5 = 450.5 -> 451, as the dashboard rounds the same sum
      expect(find.text('451 ${l10nEn.kcalLabel}'), findsOneWidget);
    });

    testWidgets('follows the kJ setting', (tester) async {
      await tester.pumpWidget(_list(_activities, usesKilojoules: true));
      await tester.pump();

      // 450.5 kcal * 4.184 = 1884.9 -> 1885
      expect(find.text('1885 ${l10nEn.kjLabel}'), findsOneWidget);
    });

    testWidgets('is hidden when no activity is logged', (tester) async {
      await tester.pumpWidget(_list(const []));
      await tester.pump();

      expect(find.textContaining(l10nEn.kcalLabel), findsNothing);
    });
  });
}
