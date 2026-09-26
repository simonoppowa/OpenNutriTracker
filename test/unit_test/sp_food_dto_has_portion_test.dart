import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';

/// A `food_summary` row as `search_food_summary` sends it: the columns the
/// view has always had, plus — once the backend's
/// `2026-09-13_food_summary_has_portion` migration is applied —
/// `has_portion`.
Map<String, dynamic> row({bool sendsFlag = false, bool? hasPortion}) => {
  SPConst.foodId: 2707829,
  SPConst.foodSource: 'fdc_survey',
  SPConst.foodSourceCode: '2707829',
  SPConst.foodName: 'Muffin, NFS',
  SPConst.foodShortTitle: 'Muffin',
  if (sendsFlag) SPConst.foodHasPortion: hasPortion,
};

void main() {
  group('SpFoodDTO.hasPortion (#1190)', () {
    test('reads the column the backend sends, true or false', () {
      expect(
        SpFoodDTO.fromJson(row(sendsFlag: true, hasPortion: true)).hasPortion,
        isTrue,
      );
      expect(
        SpFoodDTO.fromJson(row(sendsFlag: true, hasPortion: false)).hasPortion,
        isFalse,
      );
    });

    test('a backend that does not send the column leaves it null', () {
      // The live backend before that migration: the row arrives without the
      // key at all, and absence is not "no portion" — the cut applies no
      // penalty and no key to a null, and behaves as it did before the
      // column existed.
      final dto = SpFoodDTO.fromJson(row());

      expect(dto.hasPortion, isNull);
      expect(dto.name, 'Muffin, NFS');
    });

    test('an explicit null is null too, not false', () {
      expect(
        SpFoodDTO.fromJson(row(sendsFlag: true, hasPortion: null)).hasPortion,
        isNull,
      );
    });

    test('the column round-trips through toJson', () {
      // BackendPoolFixtures.flagged builds its rows through exactly this
      // round trip — a fixture row's JSON plus the column — so the DTO's
      // reading of the column is what those tests exercise.
      final json = SpFoodDTO.fromJson(
        row(sendsFlag: true, hasPortion: true),
      ).toJson();

      expect(json[SPConst.foodHasPortion], isTrue);
      expect(SpFoodDTO.fromJson(json).hasPortion, isTrue);
    });
  });
}
