import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';

/// Backend records as the resolver sees them, copied from the live backend
/// on 2026-09-12 for #1164: `food.id`, `food.source`, `food.description`,
/// `food.short_title` — the text the scorers read; no row here is without
/// one, BLS included — and every portion
/// `portions_by_food_ids(ARRAY[id], 'en')` returns for the id — the
/// deliverable rows, after the RPC's own filter, which is what
/// `MealEntity.portions` holds after `ProductsRepository` decorates a
/// fresh search page. (A copy read back from the search cache holds none:
/// `MealDBO` does not persist portions. These fixtures are the fresh
/// page; see `_noPortionsPenalty` in `resolver_relevance.dart` for what
/// that leaves out.) The counts differ from raw `food_portion` row counts
/// ("Milk, NFS" has six rows and three deliverable portions), and the
/// deliverable count is the one the tie-break sees.
///
/// The short title is not on the entity: `MealEntity.scoringName` derives
/// it from the description, and [shortTitleOf] keeps the column's value
/// beside each row so a test can hold the derivation to it.
///
/// Each family is a set of survey siblings under one short title, so they
/// score identically on the one-word query for it, which is exactly the
/// tie the resolver has to break well.
class BackendSiblingFixtures {
  static final _shortTitles = <String, String>{};

  /// `food.short_title` as the backend carries it for [record], which must
  /// be one of the rows here.
  static String shortTitleOf(MealEntity record) => _shortTitles[record.code]!;

  static MealEntity _record(
    int id,
    String description, {
    required String shortTitle,
    String source = 'fdc_survey',
    List<(String, double)> portions = const [],
  }) {
    _shortTitles['$id'] = shortTitle;
    return MealEntity(
      code: '$id',
      name: description,
      url: null,
      mealQuantity: null,
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: 'g',
      servingSize: null,
      nutriments: MealNutrimentsEntity.empty(),
      source: MealSourceEntity.fdc,
      backendSource: source,
      portions: [
        for (final (label, gramWeight) in portions)
          MealPortionEntity(
            label: label,
            gramWeight: gramWeight,
            localized: false,
          ),
      ],
    );
  }

  // apple

  static final appleRaw = _record(
    2709215,
    'Apple, raw',
    shortTitle: 'Apple',
    portions: [
      ('1 small', 165),
      ('1 medium', 200),
      ('1 large', 242),
      ('1 extra large', 295),
      ('1 slice', 25),
      ('1 cup', 125),
      ('1 single serving package', 34),
    ],
  );
  static final appleDried = _record(
    2709196,
    'Apple, dried',
    shortTitle: 'Apple',
    portions: [('1 slice/chunk', 8), ('1 cup', 90)],
  );
  static final appleBaked = _record(
    2709220,
    'Apple, baked',
    shortTitle: 'Apple',
    portions: [('1 apple, any size', 210), ('1 cup', 190)],
  );
  static List<MealEntity> get apple => [appleDried, appleBaked, appleRaw];

  // egg

  static final eggWholeRaw = _record(
    2707152,
    'Egg, whole, raw',
    shortTitle: 'Egg',
    portions: [('1 egg', 50), ('1 cup', 245)],
  );
  static final eggWholeBoiledOrPoached = _record(
    2707154,
    'Egg, whole, boiled or poached',
    shortTitle: 'Egg',
    portions: [('1 egg', 50), ('1 cup', 135), ('1 slice', 5)],
  );
  static final eggCreamed = _record(
    2707179,
    'Egg, creamed',
    shortTitle: 'Egg',
    portions: [('1 egg', 145), ('1 cup', 135)],
  );
  static final eggYolkOnlyRaw = _record(
    2707172,
    'Egg, yolk only, raw',
    shortTitle: 'Egg',
    portions: [('1 egg', 17), ('1 cup', 245)],
  );
  static List<MealEntity> get egg => [
    eggWholeRaw,
    eggWholeBoiledOrPoached,
    eggCreamed,
    eggYolkOnlyRaw,
  ];

  // eggplant

  /// Three backend records with the same full description — one per FDC
  /// data type, each with its own nutrient profile — so a name-keyed
  /// collapse folds them even with full descriptions shown. Only the
  /// survey record carries deliverable portions.
  static final eggplantRawSrLegacy = _record(
    169228,
    'Eggplant, raw',
    shortTitle: 'Eggplant',
    source: 'fdc_sr_legacy',
  );
  static final eggplantRawFoundation = _record(
    2685577,
    'Eggplant, raw',
    shortTitle: 'Eggplant',
    source: 'fdc_foundation',
  );
  static final eggplantRawSurvey = _record(
    2709785,
    'Eggplant, raw',
    shortTitle: 'Eggplant',
    portions: [('1 whole', 500), ('1 cup', 80)],
  );
  static List<MealEntity> get eggplant => [
    eggplantRawSrLegacy,
    eggplantRawFoundation,
    eggplantRawSurvey,
  ];

  // milk

  static final milkNfs = _record(
    2705384,
    'Milk, NFS',
    shortTitle: 'Milk',
    portions: [
      ('1 cup', 244),
      ('1 fl oz', 30.5),
      ('1 individual school container', 244),
    ],
  );
  static final milkWhole = _record(
    2705385,
    'Milk, whole',
    shortTitle: 'Milk',
    portions: [
      ('1 cup', 244),
      ('1 fl oz', 30.5),
      ('1 individual school container', 244),
    ],
  );
  static final milkHuman = _record(
    2705383,
    'Milk, human',
    shortTitle: 'Milk',
    portions: [('1 cup', 246), ('1 fl oz', 30.8)],
  );
  // "Milk, whole" ahead of "Milk, NFS" on purpose: the two tie on portions
  // (three each), so only the name-length key puts NFS first.
  static List<MealEntity> get milk => [milkHuman, milkWhole, milkNfs];

  // banana

  static final bananaRaw = _record(
    2709224,
    'Banana, raw',
    shortTitle: 'Banana',
    portions: [
      ('1 banana', 126),
      ('1 slice', 6),
      ('1 cup', 150),
      ('1 cup, mashed', 225),
      ('1 linear inch', 15),
    ],
  );
  static final bananaBaked = _record(
    2709225,
    'Banana, baked',
    shortTitle: 'Banana',
    portions: [('1 banana', 140), ('1 cup', 140)],
  );
  static List<MealEntity> get banana => [bananaBaked, bananaRaw];

  // bread

  /// The one family here where the two tie-break keys disagree: white
  /// bread carries more portions, rye the shorter name. In apple, banana
  /// and milk the most-portioned sibling is also the shortest-named, so
  /// those cannot tell the portions key from the name-length key.
  static final breadWhite = _record(
    2707598,
    'Bread, white',
    shortTitle: 'Bread',
    portions: [
      ('1 small or thin/very thin slice', 24),
      ('1 medium or regular slice', 28),
      ('1 large or thick slice', 43),
      ('1 slice, crust not eaten', 13),
      ('1 slice, snack-size', 10),
      ('1 cup', 40),
      ('1 cubic inch', 2.8),
    ],
  );
  static final breadRye = _record(
    2707755,
    'Bread, rye',
    shortTitle: 'Bread',
    portions: [
      ('1 slice, snack-size', 10),
      ('1 slice, crust not eaten', 15),
      ('1 small or thin/very thin slice', 25),
      ('1 medium or regular slice', 32),
      ('1 large or thick slice', 43),
    ],
  );
  static List<MealEntity> get bread => [breadRye, breadWhite];

  // rice

  static final riceCookedNfs = _record(
    2708402,
    'Rice, cooked, NFS',
    shortTitle: 'Rice',
    portions: [('1 cup, cooked', 158)],
  );
  static final ricePuertoRican = _record(
    2708432,
    'Rice, white, cooked with fat, Puerto Rican style',
    shortTitle: 'Rice',
    portions: [('1 cup, cooked', 155)],
  );
  static List<MealEntity> get rice => [ricePuertoRican, riceCookedNfs];

  /// Two records that tie the resolver's every key on the query `rice`:
  /// titled "Bread" and "Chips", so both score nothing, and then five
  /// deliverable portions and eleven characters each. Both are in the live
  /// 100-row pool for that query, and while they were scored on their
  /// descriptions both outscored "Rice, cooked, NFS" there (two tokens
  /// against three) — see the determinism test and the rice test.
  static final breadRice = _record(
    2707794,
    'Bread, rice',
    shortTitle: 'Bread',
    portions: [
      ('1 small or thin/very thin slice', 24),
      ('1 medium or regular slice', 28),
      ('1 large or thick slice', 43),
      ('1 slice, crust not eaten', 13),
      ('1 slice, snack-size', 10),
    ],
  );
  static final chipsRice = _record(
    2708161,
    'Chips, rice',
    shortTitle: 'Chips',
    portions: [
      ('1 chip', 1),
      ('1 small single serving bag', 28),
      ('1 medium single serving bag', 57),
      ('1 large single serving bag', 85),
      ('1 cup', 30),
    ],
  );

  // orange juice

  /// BLS carries the exact title — as its short title too, so it scores
  /// the same either way — and not one portion the RPC would deliver.
  static final orangeJuiceBls = _record(
    10000266,
    'Orange juice',
    shortTitle: 'Orange juice',
    source: 'bls',
  );

  /// The nearest survey record. There is no `food` row named exactly
  /// "Orange juice, 100%"; the survey's plain one carries FNDDS's `NFS`,
  /// and its short title is the BLS record's name letter for letter.
  static final orangeJuice100Nfs = _record(
    2709186,
    'Orange juice, 100%, NFS',
    shortTitle: 'Orange juice',
    portions: [
      ('1 fl oz (no ice)', 31),
      ('1 fl oz (with ice)', 23),
      ('1 fun size box (4.23 fl oz)', 131),
      ('1 juice box/pouch (6.75 fl oz)', 209),
      ('1 individual school container', 124),
    ],
  );
  static List<MealEntity> get orangeJuice => [
    orangeJuiceBls,
    orangeJuice100Nfs,
  ];

  // chicken breast

  static final chickenBreastBaked = _record(
    2705956,
    'Chicken breast, baked, broiled, or roasted, skin not eaten, from raw',
    shortTitle: 'Chicken breast',
    portions: [
      ('1 cup, cooked, diced', 135),
      ('1 small breast', 105),
      ('1 medium breast', 120),
      ('1 large breast', 135),
      ('1 small or thin slice', 30),
      ('1 medium slice', 60),
      ('1 large or thick slice', 85),
      ('1 oz, cooked', 28.35),
      ('1 breast quarter (yield after cooking, bone removed)', 155),
    ],
  );
  static final chickenBreastRotisserie = _record(
    2705963,
    'Chicken breast, rotisserie, skin eaten',
    shortTitle: 'Chicken breast',
    portions: [
      ('1 cup, cooked, diced', 135),
      ('1 breast', 130),
      ('1 small or thin slice', 30),
      ('1 medium slice', 60),
      ('1 large or thick slice', 85),
      ('1 oz, cooked', 28.35),
      ('1 breast quarter (yield after cooking, bone removed)', 155),
    ],
  );
  static final chickenBreastNsCookingMethod = _record(
    2705953,
    'Chicken breast, NS as to cooking method, skin eaten',
    shortTitle: 'Chicken breast',
    portions: [
      ('1 cup, cooked, diced', 135),
      ('1 breast', 130),
      ('1 small or thin slice', 30),
      ('1 medium slice', 60),
      ('1 large or thick slice', 85),
      ('1 oz, cooked', 28.35),
      ('1 breast quarter (yield after cooking, bone removed)', 155),
    ],
  );

  /// SR Legacy: a real record with nothing the RPC would deliver.
  static final chickenBreastRollSrLegacy = _record(
    174608,
    'Chicken breast, roll, oven-roasted',
    shortTitle: 'Chicken breast',
    source: 'fdc_sr_legacy',
  );
  static List<MealEntity> get chickenBreast => [
    chickenBreastRollSrLegacy,
    chickenBreastBaked,
    chickenBreastNsCookingMethod,
    chickenBreastRotisserie,
  ];

  /// Every row above, once each.
  static List<MealEntity> get all => [
    ...apple,
    ...egg,
    ...eggplant,
    ...milk,
    ...banana,
    ...bread,
    ...rice,
    breadRice,
    chipsRice,
    ...orangeJuice,
    ...chickenBreast,
  ];
}
