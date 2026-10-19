import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/features/add_meal/domain/search/search_region.dart';
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
  late SearchRegion region;

  setUp(() {
    config = _FakeConfigDataSource();
    region = SearchRegion(config);
  });

  test('Germany until the user picks another region', () async {
    expect(await region.country(), 'DE');
    expect(await region.offCountryTag(), 'en:germany');
  });

  test('a picked region is stored and used for the country boost', () async {
    await region.save('AT');

    expect(config.config.offSearchCountry, 'AT');
    expect(await region.offCountryTag(), 'en:austria');
  });

  test('an unknown stored region falls back to Germany', () async {
    config.config.offSearchCountry = 'XX';

    expect(await region.country(), 'DE');
  });

  test('every offered region has an Open Food Facts tag', () {
    for (final country in SearchRegion.countries) {
      expect(SearchRegion.offTagOf(country), isNotNull, reason: country);
    }
    expect(SearchRegion.countries.first, 'DE');
  });

  test('the region travels in the backup', () {
    expect(PersonalBackupExtras.appSettingKeys, contains('offSearchCountry'));
  });

  test('a flag for each region', () {
    expect(SearchRegion.flagOf('DE'), '🇩🇪');
  });
}
