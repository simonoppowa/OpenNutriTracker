import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:horizontal_picker/horizontal_picker.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/body_weight_input.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_target_weight_dialog.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_weight_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../helpers/fake_hive_db_provider.dart';
import '../../../../helpers/hive_test_setup.dart';
import '../../../../helpers/test_l10n.dart';

class _FakeConfigRepository extends Fake implements ConfigRepository {
  bool useText = false;

  @override
  Future<bool> getUseTextForWeightInput() async => useText;

  @override
  Future<void> setUseTextForWeightInput(bool value) async {
    useText = value;
  }
}

Widget _wrapWithL10n(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('ConfigDataSource.useTextForWeightInput round-trip', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      registerHiveAdaptersOnce();
    });

    test(
      'useTextForWeightInput preference survives reopening the Hive box',
      () async {
        Hive.init('.');
        final boxName =
            'config_weight_input_test_${DateTime.now().microsecondsSinceEpoch}';
        final box = await Hive.openBox<ConfigDBO>(boxName);
        await box.put('ConfigKey', ConfigDBO.empty());

        final firstSource = ConfigDataSource(
          FakeHiveDBProvider(configBox: box),
        );
        expect(await firstSource.getUseTextForWeightInput(), isFalse);

        await firstSource.setUseTextForWeightInput(true);
        await box.close();

        final reopenedBox = await Hive.openBox<ConfigDBO>(boxName);
        addTearDown(() => reopenedBox.deleteFromDisk());

        final secondSource = ConfigDataSource(
          FakeHiveDBProvider(configBox: reopenedBox),
        );
        expect(await secondSource.getUseTextForWeightInput(), isTrue);
      },
    );
  });

  group('SetWeightDialog & SetTargetWeightDialog input mode toggle', () {
    late _FakeConfigRepository configRepository;

    setUp(() {
      configRepository = _FakeConfigRepository();
    });

    testWidgets(
      'defaults to slider and persists switching to text input mode',
      (tester) async {
        await tester.pumpWidget(
          _wrapWithL10n(
            SetWeightDialog(
              initialKg: 75.0,
              unit: BodyWeightUnit.kg,
              configRepository: configRepository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(HorizontalPicker), findsOneWidget);
        expect(find.byType(BodyWeightInput), findsNothing);
        expect(find.byTooltip(l10nEn.weightInputPickerTooltip), findsOneWidget);
        expect(
          find.byTooltip(l10nEn.weightInputKeyboardTooltip),
          findsOneWidget,
        );

        await tester.tap(find.byIcon(Icons.keyboard_alt_outlined));
        await tester.pumpAndSettle();

        expect(find.byType(BodyWeightInput), findsOneWidget);
        expect(find.byType(HorizontalPicker), findsNothing);
        expect(configRepository.useText, isTrue);
      },
    );

    testWidgets(
      'restores text input mode across dialogs and submits typed weight',
      (tester) async {
        configRepository.useText = true;
        double? submittedWeight;

        await tester.pumpWidget(
          _wrapWithL10n(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  submittedWeight = await showDialog<double>(
                    context: context,
                    builder: (_) => SetWeightDialog(
                      initialKg: 75.0,
                      unit: BodyWeightUnit.kg,
                      configRepository: configRepository,
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.byType(BodyWeightInput), findsOneWidget);

        await tester.enterText(find.byType(TextField), '82.4');
        await tester.pumpAndSettle();

        await tester.tap(find.text(l10nEn.dialogOKLabel));
        await tester.pumpAndSettle();

        expect(submittedWeight, closeTo(82.4, 0.01));
      },
    );

    testWidgets(
      'SetTargetWeightDialog shares persisted text mode preference',
      (tester) async {
        configRepository.useText = true;

        await tester.pumpWidget(
          _wrapWithL10n(
            SetTargetWeightDialog(
              initialKg: 70.0,
              hasExistingTarget: false,
              unit: BodyWeightUnit.kg,
              configRepository: configRepository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BodyWeightInput), findsOneWidget);
        expect(find.byType(HorizontalPicker), findsNothing);
      },
    );
  });

  group('typed weight in text mode', () {
    late _FakeConfigRepository configRepository;

    setUp(() {
      configRepository = _FakeConfigRepository()..useText = true;
    });

    TextButton okButton(WidgetTester tester) => tester.widget<TextButton>(
      find.widgetWithText(TextButton, l10nEn.dialogOKLabel),
    );

    testWidgets('an out-of-range value disables OK instead of closing', (
      tester,
    ) async {
      final popped = await _openDialog(
        tester,
        _kgWeightDialog(configRepository),
      );

      await tester.enterText(find.byType(TextField), '999');
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nEn.dialogOKLabel));
      await tester.pumpAndSettle();

      expect(popped, isEmpty);
      expect(find.byType(SetWeightDialog), findsOneWidget);
      expect(okButton(tester).onPressed, isNull);
    });

    testWidgets('an emptied field disables OK on the target dialog', (
      tester,
    ) async {
      final popped = await _openDialog(
        tester,
        SetTargetWeightDialog(
          initialKg: 70,
          hasExistingTarget: false,
          unit: BodyWeightUnit.lb,
          configRepository: configRepository,
        ),
      );

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nEn.dialogOKLabel));
      await tester.pumpAndSettle();

      expect(popped, isEmpty);
      expect(find.byType(SetTargetWeightDialog), findsOneWidget);
      expect(okButton(tester).onPressed, isNull);
    });

    testWidgets('a comma decimal is read as a decimal point', (tester) async {
      final popped = await _openDialog(
        tester,
        _kgWeightDialog(configRepository),
      );

      await tester.enterText(find.byType(TextField), '82,4');
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nEn.dialogOKLabel));
      await tester.pumpAndSettle();

      expect(popped.single as double, closeTo(82.4, 1e-9));
    });

    testWidgets('a typed pound value is popped as kilograms', (tester) async {
      final popped = await _openDialog(
        tester,
        SetTargetWeightDialog(
          initialKg: 70,
          hasExistingTarget: false,
          unit: BodyWeightUnit.lb,
          configRepository: configRepository,
        ),
      );

      expect(find.text(l10nEn.lbsLabel), findsOneWidget);
      await tester.enterText(find.byType(TextField), '180');
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nEn.dialogOKLabel));
      await tester.pumpAndSettle();

      final result = popped.single as TargetWeightDialogResult;
      expect(result.value, closeTo(UnitCalc.lbsToKg(180), 1e-9));
    });

    testWidgets('switching to the picker mid-edit keeps the typed value', (
      tester,
    ) async {
      final popped = await _openDialog(
        tester,
        _kgWeightDialog(configRepository),
      );

      await tester.enterText(find.byType(TextField), '90');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.linear_scale));
      await tester.pumpAndSettle();
      expect(find.byType(HorizontalPicker), findsOneWidget);
      expect(configRepository.useText, isFalse);

      // And back again: the text field is reseeded from the same value.
      await tester.tap(find.byIcon(Icons.keyboard_alt_outlined));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, '90'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.linear_scale));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nEn.dialogOKLabel));
      await tester.pumpAndSettle();

      expect(popped.single, 90);
    });

    testWidgets(
      'switching to the picker with a low weight (< 51 kg) positions on the typed value instead of the bounds midpoint',
      (tester) async {
        final popped = await _openDialog(
          tester,
          _kgWeightDialog(configRepository),
        );

        await tester.enterText(find.byType(TextField), '40');
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.linear_scale));
        await tester.pumpAndSettle();

        final wheel = tester.widget<ListWheelScrollView>(
          find.byType(ListWheelScrollView),
        );
        final controller = wheel.controller as FixedExtentScrollController;
        // Bounds are 1..90 kg with 890 divisions (0.1 kg per step), so 40.0 kg
        // sits at index 390 rather than the 1..90 midpoint (45.5 kg).
        expect(controller.selectedItem, 390);

        await tester.tap(find.text(l10nEn.dialogOKLabel));
        await tester.pumpAndSettle();

        expect(popped.single as double, closeTo(40.0, 1e-9));
      },
    );
  });

  group('picker opened at a low weight', () {
    // Below 51 kg (101 lb) the picker's lower bound clamps at 1, so its
    // midpoint is no longer the user's weight. It must still open on it.
    int selectedItem(WidgetTester tester) {
      final wheel = tester.widget<ListWheelScrollView>(
        find.byType(ListWheelScrollView),
      );
      return (wheel.controller! as FixedExtentScrollController).selectedItem;
    }

    testWidgets('the weight dialog opens on 45 kg and saves it', (
      tester,
    ) async {
      final popped = await _openDialog(
        tester,
        SetWeightDialog(
          initialKg: 45,
          unit: BodyWeightUnit.kg,
          configRepository: _FakeConfigRepository(),
        ),
      );

      // Bounds 1..95 kg in 0.1 kg steps: 45 kg is item 440.
      expect(selectedItem(tester), 440);
      await tester.tap(find.text(l10nEn.dialogOKLabel));
      await tester.pumpAndSettle();

      expect(popped.single as double, closeTo(45, 1e-9));
    });

    testWidgets('the target dialog opens on 80 lb and saves it', (
      tester,
    ) async {
      final popped = await _openDialog(
        tester,
        SetTargetWeightDialog(
          initialKg: UnitCalc.lbsToKg(80),
          hasExistingTarget: false,
          unit: BodyWeightUnit.lb,
          configRepository: _FakeConfigRepository(),
        ),
      );

      // Bounds 1..180 lb in 0.1 lb steps: 80 lb is item 790.
      expect(selectedItem(tester), 790);
      await tester.tap(find.text(l10nEn.dialogOKLabel));
      await tester.pumpAndSettle();

      final result = popped.single as TargetWeightDialogResult;
      expect(result.value, closeTo(UnitCalc.lbsToKg(80), 1e-6));
    });
  });

  group('stones', () {
    // Stones always use the text fields. They must open on the stored weight,
    // not on 0 st 0 lb, and OK must save it unchanged.
    Future<void> expectSeededAndSaved(
      WidgetTester tester,
      Widget dialog,
      double Function(Object? popped) kgOf,
    ) async {
      final popped = await _openDialog(tester, dialog);

      expect(find.widgetWithText(TextField, '11'), findsOneWidget);
      expect(find.widgetWithText(TextField, '0.3'), findsOneWidget);
      await tester.tap(find.text(l10nEn.dialogOKLabel));
      await tester.pumpAndSettle();

      expect(kgOf(popped.single), closeTo(70, 1e-9));
    }

    testWidgets('the weight dialog opens on the stored weight', (tester) async {
      await expectSeededAndSaved(
        tester,
        SetWeightDialog(
          initialKg: 70,
          unit: BodyWeightUnit.st,
          configRepository: _FakeConfigRepository(),
        ),
        (popped) => popped as double,
      );
    });

    testWidgets('the target dialog opens on the stored weight', (tester) async {
      await expectSeededAndSaved(
        tester,
        SetTargetWeightDialog(
          initialKg: 70,
          hasExistingTarget: false,
          unit: BodyWeightUnit.st,
          configRepository: _FakeConfigRepository(),
        ),
        (popped) => (popped as TargetWeightDialogResult).value!,
      );
    });
  });
  group('dialog title beside the mode toggle', () {
    // The toggle now shares the title row, so at a large font the title must
    // ellipsize on one line rather than overflow. AutoSizeText cannot be used
    // here: AlertDialog asks its title for an intrinsic width, which
    // AutoSizeText's LayoutBuilder cannot report.
    Future<void> pumpLarge(WidgetTester tester, Widget dialog) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: _wrapWithL10n(dialog),
        ),
      );
      await tester.pumpAndSettle();
    }

    void expectOneLineTitle(WidgetTester tester, String title) {
      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.text(title));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    }

    testWidgets('the weight dialog title fits at a large font', (tester) async {
      await pumpLarge(tester, _kgWeightDialog(_FakeConfigRepository()));

      expectOneLineTitle(tester, l10nEn.selectWeightDialogLabel);
    });

    testWidgets('the target weight dialog title fits at a large font', (
      tester,
    ) async {
      await pumpLarge(
        tester,
        SetTargetWeightDialog(
          initialKg: 70,
          hasExistingTarget: false,
          unit: BodyWeightUnit.kg,
          configRepository: _FakeConfigRepository(),
        ),
      );

      expectOneLineTitle(tester, l10nEn.profileTargetWeightLabel);
    });
  });
}

/// Opens [dialog] from a button. The returned list gains the popped value
/// when the dialog closes, so an empty list means it is still open.
Future<List<Object?>> _openDialog(WidgetTester tester, Widget dialog) async {
  final popped = <Object?>[];
  await tester.pumpWidget(
    _wrapWithL10n(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            popped.add(
              await showDialog<Object>(
                context: context,
                builder: (_) => dialog,
              ),
            );
          },
          child: const Text('Open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return popped;
}

SetWeightDialog _kgWeightDialog(ConfigRepository configRepository) =>
    SetWeightDialog(
      initialKg: 75,
      unit: BodyWeightUnit.kg,
      configRepository: configRepository,
    );
