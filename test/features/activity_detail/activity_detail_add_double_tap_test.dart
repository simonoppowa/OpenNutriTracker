import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/activity_detail/presentation/bloc/activity_detail_bloc.dart';
import 'package:opennutritracker/features/activity_detail/presentation/widget/activity_detail_bottom_sheet.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../fixture/physical_activity_entity_fixtures.dart';

class _FakeActivityDetailBloc extends Fake implements ActivityDetailBloc {}

/// #1317 review: the save can wait for the tracked-day lock with the
/// screen still open, so Add has to take one tap per save.
void main() {
  late Completer<void> save;
  late int saves;

  Future<void> pumpSheet(WidgetTester tester) async {
    saves = 0;
    save = Completer<void>();
    await tester.pumpWidget(
      ChangeNotifierProvider<EnergyUnitProvider>(
        create: (_) => EnergyUnitProvider(),
        child: MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: ActivityDetailBottomSheet(
              activityEntity: PhysicalActivityFixtures.moderateBicycling,
              quantityTextController: TextEditingController(text: '30'),
              activityDetailBloc: _FakeActivityDetailBloc(),
              onAddButtonPressed: (_, {templateName, saveAsTemplate = false}) {
                saves++;
                return save.future;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder addButton() => find.byIcon(Icons.add_rounded);

  bool addEnabled(WidgetTester tester) =>
      tester
          .widget<ButtonStyleButton>(
            find.ancestor(
              of: addButton(),
              matching: find.bySubtype<ButtonStyleButton>(),
            ),
          )
          .onPressed !=
      null;

  testWidgets('a second tap while the save is pending logs nothing', (
    tester,
  ) async {
    await pumpSheet(tester);

    await tester.tap(addButton());
    await tester.tap(addButton(), warnIfMissed: false);
    await tester.pump();

    expect(saves, 1);
    expect(addEnabled(tester), isFalse);
  });

  testWidgets('Add is enabled again once a save ends without leaving', (
    tester,
  ) async {
    await pumpSheet(tester);

    await tester.tap(addButton());
    await tester.pump();
    save.complete();
    await tester.pump();

    expect(addEnabled(tester), isTrue);
    await tester.tap(addButton());
    expect(saves, 2);
  });
}
