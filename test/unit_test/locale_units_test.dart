import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/utils/locale_units.dart';
import 'package:opennutritracker/core/utils/off_country.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';

void main() {
  group('countryCodeFromLocale', () {
    test('reads the country from the common locale spellings', () {
      expect(countryCodeFromLocale('en_GB'), 'GB');
      expect(countryCodeFromLocale('en-GB'), 'GB');
      expect(countryCodeFromLocale('en_GB.UTF-8'), 'GB');
      expect(countryCodeFromLocale('de_AT'), 'AT');
    });

    test('upper-cases a lower-case country segment', () {
      expect(countryCodeFromLocale('en_us'), 'US');
    });

    test('returns null when there is no country segment', () {
      expect(countryCodeFromLocale('en'), isNull);
      expect(countryCodeFromLocale('C'), isNull);
      expect(countryCodeFromLocale('en_'), isNull);
    });
  });

  group('OffCountry still resolves after sharing the parser', () {
    test('maps a country locale to its OFF tag', () {
      expect(OffCountry.fromLocale('de_DE'), 'en:germany');
      expect(OffCountry.fromLocale('en_GB.UTF-8'), 'en:united-kingdom');
    });

    test('returns null for an unmapped or country-less locale', () {
      expect(OffCountry.fromLocale('en'), isNull);
      expect(OffCountry.fromLocale('xx_ZZ'), isNull);
    });
  });

  group('LocaleUnitDefaults.fromLocale', () {
    test('US is fully imperial', () {
      final defaults = LocaleUnitDefaults.fromLocale('en_US');

      expect(defaults.heightUsesImperial, isTrue);
      expect(defaults.bodyWeightUnit, BodyWeightUnit.lb);
      expect(defaults.foodUsesImperial, isTrue);
    });

    test('Liberia and Myanmar match the US', () {
      for (final locale in ['en_LR', 'my_MM']) {
        final defaults = LocaleUnitDefaults.fromLocale(locale);
        expect(defaults.heightUsesImperial, isTrue, reason: locale);
        expect(defaults.bodyWeightUnit, BodyWeightUnit.lb, reason: locale);
        expect(defaults.foodUsesImperial, isTrue, reason: locale);
      }
    });

    test('GB gets feet and stones but metric food', () {
      final defaults = LocaleUnitDefaults.fromLocale('en_GB');

      expect(defaults.heightUsesImperial, isTrue);
      expect(defaults.bodyWeightUnit, BodyWeightUnit.st);
      expect(
        defaults.foodUsesImperial,
        isFalse,
        reason: 'UK food labelling is metric',
      );
    });

    test('unlisted countries stay metric', () {
      for (final locale in ['de_DE', 'fr_FR', 'en_CA', 'en_AU', 'ja_JP']) {
        final defaults = LocaleUnitDefaults.fromLocale(locale);
        expect(defaults.heightUsesImperial, isFalse, reason: locale);
        expect(defaults.bodyWeightUnit, BodyWeightUnit.kg, reason: locale);
        expect(defaults.foodUsesImperial, isFalse, reason: locale);
      }
    });

    test('a locale without a country falls back to metric', () {
      for (final locale in ['en', 'C', '']) {
        final defaults = LocaleUnitDefaults.fromLocale(locale);
        expect(defaults.heightUsesImperial, isFalse, reason: locale);
        expect(defaults.bodyWeightUnit, BodyWeightUnit.kg, reason: locale);
      }
    });
  });

  group('defaultFoodSourceToggles', () {
    test('German-speaking locales get the BLS and drop US branded foods', () {
      for (final locale in ['de_DE', 'de_AT', 'de_CH']) {
        final toggles = defaultFoodSourceToggles(locale);
        expect(toggles['bls'], isTrue, reason: locale);
        expect(toggles['fdc_branded'], isFalse, reason: locale);
        // The generic FDC sources stay: food_translation gives them German
        // names, so they read as reference entries rather than noise.
        expect(toggles['fdc_foundation'], isTrue, reason: locale);
        expect(toggles['fdc_sr_legacy'], isTrue, reason: locale);
        expect(toggles['fdc_survey'], isTrue, reason: locale);
      }
    });

    test('everywhere else gets the FDC set and no BLS', () {
      for (final locale in ['en_US', 'en_GB', 'it_IT', 'pl_PL']) {
        final toggles = defaultFoodSourceToggles(locale);
        expect(toggles['bls'], isFalse, reason: locale);
        expect(toggles['fdc_branded'], isTrue, reason: locale);
        expect(toggles['fdc_foundation'], isTrue, reason: locale);
      }
    });

    test('a locale without a country is treated as non-German', () {
      final toggles = defaultFoodSourceToggles('de');
      expect(toggles['bls'], isFalse);
      expect(toggles['fdc_branded'], isTrue);
    });

    test('covers exactly the selectable sources', () {
      expect(
        defaultFoodSourceToggles('en_US').keys.toSet(),
        SPConst.settingsSelectableFoodSources.toSet(),
        reason: 'a new backend source must be given a default here',
      );
    });
  });
}
