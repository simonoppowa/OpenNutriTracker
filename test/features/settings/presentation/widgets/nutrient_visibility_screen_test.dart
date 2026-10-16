import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/daily_nutrient_panel.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/nutrient_visibility_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../helpers/fake_reload_blocs.dart';
import '../../../../helpers/test_l10n.dart';

class _FakeGetConfigUsecase extends Fake implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(false, false, false, AppThemeEntity.system);
}

class _FakeAddConfigUsecase extends Fake implements AddConfigUsecase {
  final List<String> log;
  Map<String, bool>? saved;

  _FakeAddConfigUsecase(this.log);

  @override
  Future<void> setConfigNutrientPanelVisibility(
    Map<String, bool> visibility,
  ) async {
    await Future<void>.delayed(Duration.zero);
    saved = Map<String, bool>.from(visibility);
    log.add('setConfigNutrientPanelVisibility');
  }
}

void main() {
  late ReloadRecorder recorder;
  late _FakeAddConfigUsecase addConfig;

  setUp(() {
    recorder = ReloadRecorder()..register();
    addConfig = _FakeAddConfigUsecase(recorder.log);
    locator.registerSingleton<GetConfigUsecase>(_FakeGetConfigUsecase());
    locator.registerSingleton<AddConfigUsecase>(addConfig);
  });

  tearDown(() async => locator.reset());

  testWidgets(
    'unticking a nutrient reloads the open diary day, whose panel then '
    're-reads the visibility map (#1359)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          home: const NutrientVisibilityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10nEn.ironLabel));
      await tester.pumpAndSettle();

      expect(addConfig.saved?[NutrientPanelKeys.iron], isFalse);
      expect(recorder.calendarDayReloaded, isTrue);
      expect(recorder.log.first, 'setConfigNutrientPanelVisibility');
    },
  );
}
