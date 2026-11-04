import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:horizontal_picker/horizontal_picker.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
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
}
