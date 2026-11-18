import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/locale_units.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';

void main() {
  const european = ['ciqual', 'fineli', 'frida', 'mvt', 'slv'];

  test('the European sources are selectable', () {
    expect(SPConst.settingsSelectableFoodSources, containsAll(european));
    for (final code in european) {
      expect(SPConst.foodSourceDisplayNames, contains(code));
      expect(SPConst.foodSourceWebsites, contains(code));
    }
  });

  test('each starts enabled in its own country only', () {
    final home = {
      'ciqual': 'fr_FR',
      'fineli': 'fi_FI',
      'frida': 'da_DK',
      'mvt': 'nb_NO',
      'slv': 'sv_SE',
    };
    for (final MapEntry(key: code, value: locale) in home.entries) {
      final toggles = defaultFoodSourceToggles(locale);
      for (final other in european) {
        expect(toggles[other], other == code, reason: '$other in $locale');
      }
      expect(toggles['fdc_survey'], isTrue, reason: locale);
    }
    for (final locale in ['en_US', 'es_AR', 'de_DE', 'de']) {
      final toggles = defaultFoodSourceToggles(locale);
      for (final code in european) {
        expect(toggles[code], isFalse, reason: '$code in $locale');
      }
    }
  });
}
