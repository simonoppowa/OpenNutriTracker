import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/recipes/presentation/bloc/recipe_builder_bloc.dart';

void main() {
  group('EAN-13 check digit validation', () {
    // Faber-Castell pencil pack — a real, in-the-wild EAN-13 that scans
    // cleanly off a physical product. Provides a known-good baseline
    // before we start poking at the algorithm with adversarial inputs.
    test('accepts the canonical Faber-Castell EAN', () {
      expect(
        RecipeBuilderBloc.isEan13CheckDigitValid('4006381333931'),
        isTrue,
      );
    });

    // The most likely real-world miskey: someone reads the last digit off
    // a small printed barcode and gets it wrong by one. The check should
    // refuse that, otherwise the user happily attaches a junk code to
    // their recipe and a future scan of the genuine product fails to
    // resolve.
    test('rejects the same EAN with the last digit flipped', () {
      expect(
        RecipeBuilderBloc.isEan13CheckDigitValid('4006381333930'),
        isFalse,
      );
    });

    // Non-13-digit codes use different algorithms (EAN-8 / UPC-A /
    // GTIN-14). We don't validate those here — the lenient regex in the
    // builder already covers length, and we trust the longer/shorter
    // formats at face value rather than rejecting valid codes that
    // happen not to satisfy the EAN-13 weighting.
    test('passes through 8-digit codes without check', () {
      expect(RecipeBuilderBloc.isEan13CheckDigitValid('12345678'), isTrue);
    });

    test('passes through 12-digit UPC-A codes without check', () {
      expect(
        RecipeBuilderBloc.isEan13CheckDigitValid('123456789012'),
        isTrue,
      );
    });

    test('passes through 14-digit GTIN-14 codes without check', () {
      expect(
        RecipeBuilderBloc.isEan13CheckDigitValid('12345678901231'),
        isTrue,
      );
    });
  });
}
