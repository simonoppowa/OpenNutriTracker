import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/off_const.dart';
import 'package:opennutritracker/core/utils/supported_language.dart';

/// Pins what a request to Open Food Facts carries about the user's locale.
///
/// The README and the published Data policy both described this as a *country*
/// code for a long time, which is a coarse location signal and is not what the
/// app sends. A country tag does exist in the tree — `OffCountry.fromLocale`
/// builds one — but `products_repository.dart` compares it against the
/// `countries_tags` of results that have already come back, so the boost is
/// applied on the device and the country never enters a request.
///
/// Prose drifting from the wire is what the privacy audit kept finding, so the
/// claim is asserted here rather than left to be re-read correctly next time.
void main() {
  group('what a word search sends', () {
    test('carries the language code, under langs', () {
      final url = OFFConst.getOffWordSearchUrl('apple', langs: 'de,en');

      expect(url.queryParameters['langs'], 'de,en');
    });

    test('carries no country parameter of any kind', () {
      final url = OFFConst.getOffWordSearchUrl('apple', langs: 'de,en');

      // `fields` legitimately names countries_tags — that asks OFF to return
      // which countries a product is sold in, which is a property of the
      // product and not of the person searching. Everything else must be free
      // of the user's country.
      for (final entry in url.queryParameters.entries) {
        if (entry.key == 'fields') continue;
        expect(
          entry.value.toLowerCase(),
          isNot(contains('countr')),
          reason: '${entry.key} looks like it carries a country',
        );
      }
      expect(url.queryParameters.containsKey('cc'), isFalse);
      expect(url.queryParameters.containsKey('country'), isFalse);
    });
  });

  group('what the other two requests send', () {
    test('the fallback word search sends no locale at all', () {
      // Search-a-licious being down must not change what leaves the device.
      final url = OFFConst.getOffLegacyWordSearchUrl('apple');

      expect(url.queryParameters.containsKey('langs'), isFalse);
      expect(url.queryParameters.containsKey('lc'), isFalse);
      expect(url.queryParameters.containsKey('cc'), isFalse);
    });

    test('the barcode lookup sends no locale at all', () {
      final url = OFFConst.getOffBarcodeSearchUri('737628064502');

      expect(url.queryParameters.containsKey('langs'), isFalse);
      expect(url.queryParameters.containsKey('lc'), isFalse);
      expect(url.queryParameters.containsKey('cc'), isFalse);
    });
  });

  requestedFieldsCoverEveryLocaleTheDtoReads();
}

/// OFF only returns the fields a request names. Every localized name the DTO
/// can read has to be asked for, or that locale silently gets the product's
/// primary-language name — which is what happened to cs/it/sk/tr/uk before
/// Hungarian was wired in. The expected set is derived from
/// [SupportedLanguage] so a language added to the enum without a request
/// field fails here rather than in production.
void requestedFieldsCoverEveryLocaleTheDtoReads() {
  group('what a request asks OFF to return', () {
    // pl and zh read the unsuffixed product_name (OFF rarely carries a
    // suffixed field for them); every other language reads its own.
    const readsUnsuffixed = {SupportedLanguage.pl, SupportedLanguage.zh};
    final localizedNames = [
      for (final lang in SupportedLanguage.values)
        if (!readsUnsuffixed.contains(lang)) 'product_name_${lang.name}',
      'product_name_fr', // not a UI language, but a fallback in getLocaleName
    ];

    test('the word search names every localized product name', () {
      final fields =
          OFFConst.getOffWordSearchUrl('apple').queryParameters['fields']!;
      for (final name in localizedNames) {
        expect(fields.split(','), contains(name), reason: name);
      }
    });

    test('the barcode lookup names every localized product name', () {
      final fields = OFFConst.getOffBarcodeSearchUri(
        '737628064502',
      ).queryParameters['fields']!;
      for (final name in localizedNames) {
        expect(fields.split(','), contains(name), reason: name);
      }
    });
  });
}
