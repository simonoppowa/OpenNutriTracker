import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/search/brand_query.dart';

void main() {
  test('a query without a known brand stays as it is', () {
    final query = BrandQuery.parse('Studentenfutter');

    expect(query.hasBrands, isFalse);
    expect(query.text, 'Studentenfutter');
    expect(query.offQuery, 'Studentenfutter');
  });

  test('a brand is recognised and filtered by its Open Food Facts tags', () {
    final query = BrandQuery.parse('Paradiso Mango-Maracuja');

    expect(query.hasBrands, isTrue);
    expect(query.text, 'Mango-Maracuja');
    expect(query.brandTags, {'paradiso'});
    expect(query.offQuery, 'Mango-Maracuja brands_tags:paradiso');
  });

  test('spellings of a brand come together', () {
    for (final input in [
      'Naturgut Hafermilch',
      'natur gut Hafermilch',
      'NATUR-GUT Hafermilch',
      'Naturgut Bio Hafermilch',
    ]) {
      final query = BrandQuery.parse(input);
      expect(query.brandTags, {'naturgut', 'natur-gut'}, reason: input);
      expect(query.text.toLowerCase(), contains('hafermilch'), reason: input);
    }
  });

  test('"ja!" is a brand, "ja" alone in a sentence is not', () {
    expect(BrandQuery.parse('ja! Toastbrot').brandTags, contains('ja'));
    expect(BrandQuery.parse('Toastbrot').hasBrands, isFalse);
  });

  test('a store name stands for the store and its own brands', () {
    final query = BrandQuery.parse('Penny Studentenfutter');

    expect(query.text, 'Studentenfutter');
    expect(
      query.brandTags,
      containsAll(['penny', 'naturgut', 'natur-gut', 'paradiso', 'ja']),
    );
    expect(query.offQuery, startsWith('Studentenfutter (brands_tags:'));
    expect(query.offQuery, contains(' OR '));
  });

  test('Lidl stands for Milbona, Crownfield, Pilos, Solevita and Freeway', () {
    expect(
      BrandQuery.parse('Lidl Skyr').brandTags,
      containsAll([
        'lidl',
        'milbona',
        'crownfield',
        'pilos',
        'solevita',
        'freeway',
      ]),
    );
  });

  test('multi-word brands are found', () {
    expect(
      BrandQuery.parse('Gut & Günstig Gouda').brandTags,
      contains('gut-gunstig'),
    );
    expect(
      BrandQuery.parse('REWE Beste Wahl Pesto').brandTags,
      contains('rewe-beste-wahl'),
    );
  });

  test('a query of only a brand searches the brand', () {
    final query = BrandQuery.parse('Milbona');

    expect(query.text, '');
    expect(query.offQuery, 'brands_tags:milbona');
  });

  test('a product brand is recognised in the brands of a result', () {
    final query = BrandQuery.parse('Paradiso Mango-Maracuja');

    expect(query.matchesBrands('Paradiso'), isTrue);
    expect(query.matchesBrands('Albi'), isFalse);
    expect(query.matchesBrands(null), isFalse);
    expect(
      BrandQuery.parse('Penny Studentenfutter').matchesBrands('Natur Gut'),
      isTrue,
    );
  });
}
