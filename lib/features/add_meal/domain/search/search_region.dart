import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/utils/off_country.dart';

/// The country whose products the Open Food Facts search ranks up (#41):
/// Germany unless the user picks another one, whatever the device locale
/// says. Stored app-wide in the config (field 114).
class SearchRegion {
  static const defaultCountry = 'DE';

  /// The regions offered in the settings, the default first.
  static const countries = [
    'DE',
    'AT',
    'CH',
    'NL',
    'BE',
    'FR',
    'IT',
    'ES',
    'PL',
    'DK',
    'GB',
    'US',
  ];

  final ConfigDataSource _config;

  SearchRegion(this._config);

  Future<String> country() async {
    final stored = (await _config.getConfig()).offSearchCountry;
    return countries.contains(stored) ? stored! : defaultCountry;
  }

  Future<String?> offCountryTag() async => offTagOf(await country());

  Future<void> save(String country) async {
    final config = await _config.getConfig();
    config.offSearchCountry = country;
    await _config.addConfig(config);
  }

  /// Open Food Facts' country tag for an ISO country code.
  static String? offTagOf(String country) =>
      OffCountry.fromLocale('xx_$country');

  /// The flag emoji of an ISO country code.
  static String flagOf(String country) => String.fromCharCodes(
    country.toUpperCase().codeUnits.map((unit) => 0x1F1E6 + unit - 0x41),
  );
}
