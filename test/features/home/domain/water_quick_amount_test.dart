import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/features/home/domain/water_quick_amount.dart';
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
  late WaterQuickAmount quickAmount;

  setUp(() {
    config = _FakeConfigDataSource();
    quickAmount = WaterQuickAmount(config);
  });

  test('a glass of 330 ml until the user picks an amount', () async {
    expect(await quickAmount.load(), WaterQuickAmount.defaultMl);
    expect(WaterQuickAmount.defaultMl, 330);
    expect(quickAmount.amount.value, 330);
  });

  test('a saved amount is stored and announced', () async {
    await quickAmount.save(750);

    expect(config.config.waterQuickAmountMl, 750);
    expect(quickAmount.amount.value, 750);
    expect(await WaterQuickAmount(config).load(), 750);
  });

  test('amounts outside 50 to 2000 ml are clamped', () async {
    await quickAmount.save(10);
    expect(config.config.waterQuickAmountMl, 50);

    await quickAmount.save(5000);
    expect(config.config.waterQuickAmountMl, 2000);
  });

  test('the amount travels in the backup and the config JSON', () async {
    await quickAmount.save(500);

    expect(PersonalBackupExtras.appSettingKeys, contains('waterQuickAmountMl'));
    expect(config.config.toJson()['waterQuickAmountMl'], 500);
    expect(ConfigDBO.fromJson(config.config.toJson()).waterQuickAmountMl, 500);
  });
}
