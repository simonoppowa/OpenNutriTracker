import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';

/// Pulls the ISO country segment out of a platform locale name such as
/// `en_GB`, `en-GB`, `en_GB.UTF-8`, `en` or `C`. Returns null when the
/// locale carries no country, which callers treat as "no regional signal".
String? countryCodeFromLocale(String localeName) {
  final beforeDot = localeName.split('.').first;
  final parts = beforeDot.split(RegExp('[_-]'));
  if (parts.length < 2 || parts[1].isEmpty) return null;
  return parts[1].toUpperCase();
}

/// The unit toggles onboarding starts on, derived from the device locale.
///
/// Flutter exposes no measurement-system flag, so the country segment of
/// `Platform.localeName` is the only signal available. These are starting
/// values; the user changes them on the same screen.
class LocaleUnitDefaults {
  final bool heightUsesImperial;
  final BodyWeightUnit bodyWeightUnit;
  final bool foodUsesImperial;

  const LocaleUnitDefaults({
    required this.heightUsesImperial,
    required this.bodyWeightUnit,
    required this.foodUsesImperial,
  });

  static const metric = LocaleUnitDefaults(
    heightUsesImperial: false,
    bodyWeightUnit: BodyWeightUnit.kg,
    foodUsesImperial: false,
  );

  /// The three countries that have not adopted the metric system for
  /// everyday measurement.
  static const _imperial = LocaleUnitDefaults(
    heightUsesImperial: true,
    bodyWeightUnit: BodyWeightUnit.lb,
    foodUsesImperial: true,
  );

  /// The UK measures height in feet and body weight in stones, but its food
  /// labelling is metric, which is why the three toggles are independent.
  static const _unitedKingdom = LocaleUnitDefaults(
    heightUsesImperial: true,
    bodyWeightUnit: BodyWeightUnit.st,
    foodUsesImperial: false,
  );

  static const _byCountry = <String, LocaleUnitDefaults>{
    'US': _imperial,
    'LR': _imperial,
    'MM': _imperial,
    'GB': _unitedKingdom,
  };

  /// Defaults for [localeName], falling back to metric for every country
  /// not listed and for locales with no country segment at all.
  factory LocaleUnitDefaults.fromLocale(String localeName) {
    final country = countryCodeFromLocale(localeName);
    if (country == null) return metric;
    return _byCountry[country] ?? metric;
  }
}

/// Countries whose national food composition database the app carries.
const _blsCountries = {'DE', 'AT', 'CH'};

/// Which backend food sources onboarding starts with, by locale.
///
/// Open Food Facts is always searched and is not part of this map, so
/// branded-product coverage is the same either way. Only the reference
/// database changes. A German-speaking user gets the BLS and no US
/// supermarket items; everyone else gets the FDC set and no German-language
/// BLS entries.
///
/// The FDC *generic* sources stay on for German speakers, because
/// `food_translation` surfaces those foods under German names.
Map<String, bool> defaultFoodSourceToggles(String localeName) {
  final country = countryCodeFromLocale(localeName);
  final usesBls = country != null && _blsCountries.contains(country);
  return <String, bool>{
    for (final source in SPConst.settingsSelectableFoodSources)
      source: switch (source) {
        SPConst.blsSourceCode => usesBls,
        // US branded products are the one set that is regionally wrong,
        // not merely foreign.
        'fdc_branded' => !usesBls,
        _ => true,
      },
  };
}
