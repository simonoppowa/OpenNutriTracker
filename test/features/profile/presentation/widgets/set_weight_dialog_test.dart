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
