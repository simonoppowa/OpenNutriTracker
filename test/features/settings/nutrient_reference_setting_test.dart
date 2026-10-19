import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/features/settings/domain/nutrient_reference_setting.dart';
import 'package:opennutritracker/features/settings/domain/personal_backup_extras.dart';

class _FakeConfigDataSource implements ConfigDataSource {
  ConfigDBO config = ConfigDBO(false, false, false, AppThemeDBO.system);

  @override
  Future<ConfigDBO> getConfig() async => config;

  @override
  Future<void> addConfig(ConfigDBO configDBO) async => config = configDBO;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

void main() {
  late _FakeConfigDataSource config;
  late NutrientReferenceSetting setting;

  setUp(() {
    config = _FakeConfigDataSource();
    setting = NutrientReferenceSetting(config);
  });

  test('IOM until the user picks DGE', () async {
    expect(await setting.standard(), NutrientReferenceStandard.iom);
  });

  test('a saved choice is stored and announced', () async {
    var announced = 0;
    setting.changes.addListener(() => announced++);

    await setting.save(NutrientReferenceStandard.dge);

    expect(config.config.nutrientReferenceStandard, 'dge');
    expect(await setting.standard(), NutrientReferenceStandard.dge);
    expect(announced, 1);
  });

  test('an unknown stored value reads as the default', () async {
    config.config.nutrientReferenceStandard = 'who';

    expect(await setting.standard(), NutrientReferenceStandard.iom);
  });

  test('the choice survives the JSON of the backup', () {
    config.config.nutrientReferenceStandard = 'dge';

    final restored = ConfigDBO.fromJson(config.config.toJson());

    expect(restored.nutrientReferenceStandard, 'dge');
    expect(
      PersonalBackupExtras.appSettingKeys,
      contains('nutrientReferenceStandard'),
    );
  });
}
