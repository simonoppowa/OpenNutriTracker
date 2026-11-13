import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/home/presentation/widgets/log_water_dialog.dart';
import 'package:opennutritracker/features/home/presentation/widgets/quick_water_widget.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../helpers/test_l10n.dart';

class _RecordingHomeBloc extends Fake implements HomeBloc {
  final List<int> addedMl = [];

  @override
  Future<void> addWaterIntake(int amountMl) async => addedMl.add(amountMl);
}

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: const [S.delegate],
  supportedLocales: S.supportedLocales,
  home: Scaffold(body: Center(child: child)),
);

Widget _dialogLauncher(bool usesImperialUnits) => Builder(
  builder: (context) => ElevatedButton(
    onPressed: () => showDialog<void>(
      context: context,
      builder: (_) => LogWaterDialog(usesImperialUnits: usesImperialUnits),
    ),
    child: const Text('Open'),
  ),
);

void main() {
  late _RecordingHomeBloc homeBloc;

  setUp(() {
    homeBloc = _RecordingHomeBloc();
    locator.registerSingleton<HomeBloc>(homeBloc);
  });

  tearDown(() async => locator.reset());

  group('water chip (#1306)', () {
    testWidgets('shows fl oz with imperial food units', (tester) async {
      await tester.pumpWidget(
        _app(
          const QuickWaterWidget(
            waterMlToday: 1500,
            waterGoalMl: 2000,
            usesImperialUnits: true,
          ),
        ),
      );

      expect(find.text(l10nEn.waterChipLabelFlOz(51, 68)), findsOneWidget);
    });

    testWidgets('keeps ml with metric food units', (tester) async {
      await tester.pumpWidget(
        _app(const QuickWaterWidget(waterMlToday: 1500, waterGoalMl: 2000)),
      );

      expect(find.text(l10nEn.waterChipLabel(1500, 2000)), findsOneWidget);
    });
  });

  group('log water dialog (#1306)', () {
    testWidgets('starts on a cup in fl oz and stores the amount in ml', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_dialogLauncher(true)));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.logWaterAmountLabelFlOz(8)), findsOneWidget);

      await tester.tap(find.text(l10nEn.dialogOKLabel));
      await tester.pumpAndSettle();

      // 8 fl oz = 236.6 ml
      expect(homeBloc.addedMl, [237]);
    });

    testWidgets('metric still starts on 250 ml', (tester) async {
      await tester.pumpWidget(_app(_dialogLauncher(false)));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.logWaterAmountLabel(250)), findsOneWidget);

      await tester.tap(find.text(l10nEn.dialogOKLabel));
      await tester.pumpAndSettle();

      expect(homeBloc.addedMl, [250]);
    });
  });
}
