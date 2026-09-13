import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';

/// Candidate pools copied from the live backend on 2026-09-13 for #1170.
/// No row is edited: "Potato, boiled, from fresh,  peel eaten, no added
/// fat" and "Pork and vegetables excluding  carrots, ..." carry the
/// backend's double spaces.
///
/// Two of the English ones are what the app is handed. `search_food_summary
/// (term, null, 100)` is the call `SpFoodDataSource._searchEnglish` makes
/// (`_candidatePoolSize`), and the function answers with the first hundred
/// rows whose name matches the term by full-text search, ordered by
/// `food_has_deliverable_portion(food_id) desc, food_id` — its own cut,
/// made before any client code runs. [potatoSearch] is that answer for
/// `potato`: 712 rows match, and the hundred lowest-id ones with a portion
/// are all dishes — beef and potatoes, stews, shish kabobs — with not one
/// row titled "Potato" among them; the family sits at ranks 128 to 488.
/// [breadSearch] is the answer for `bread`: 540 match, 31 of the hundred
/// are titled "Bread", and "Bread, rye" (2707755) is rank 157, outside
/// them. Beside each row, the number of portions `portions_by_food_ids(ids,
/// 'en')` delivers for it — every row in both carries at least one, which
/// is what the function's order guarantees when more than a hundred do —
/// the count `MealEntity.portions` holds once `ProductsRepository` has
/// decorated a fresh page, and what the resolver's portions key counts.
///
/// [potato] is not a pool the app is handed. It is the whole FDC survey
/// family under the short title "Potato" — all 106 `food` rows with
/// `source = 'fdc_survey'` and `short_title = 'Potato'` — in the order
/// those rows take among themselves under `search_food_summary`'s ordering,
/// with their portion counts. c78b5a38 described it as the pool the app
/// would be handed for `potato`; [potatoSearch] is that pool, and none of
/// the family is in it. The family stays because it is what the client's
/// cut has to keep the right member of when a family does reach it — the
/// twenty rows the data source keeps are the resolver's whole world for
/// the query — and the tests that use it say that it is handed to the cut
/// on its own.
///
/// The German one is `search_food_translation('Milch', 'de', 100)` as it
/// answered: the 100 `food_translation` rows the app's localized search
/// ranks and cuts, as `food_id`, `description` and `source`, in the
/// function's order. 2705384's German description is "Milch, NFS", so the
/// survey's generic milk is titled "Milch" in German as it is "Milk" in
/// English.
class BackendPoolFixtures {
  static SpFoodDTO _survey(int id, String description) => SpFoodDTO(
    foodId: id,
    source: 'fdc_survey',
    sourceCode: '$id',
    name: description,
    shortTitle: 'Potato',
  );

  /// A `food_summary` row as `search_food_summary` returns it, with the
  /// `short_title` the backend carries for it.
  static SpFoodDTO _found(
    int id,
    String description, {
    required String title,
  }) => SpFoodDTO(
    foodId: id,
    source: 'fdc_survey',
    sourceCode: '$id',
    name: description,
    shortTitle: title,
  );

  /// [row] as the resolver sees it on a fresh page: the entity built from
  /// the row, carrying as many portions as [portions] says the backend
  /// delivers for it.
  static MealEntity fresh(SpFoodDTO row, Map<int, int> portions) =>
      MealEntity.fromSpFood(row).withPortions([
        for (var i = 0; i < portions[row.foodId]!; i++)
          MealPortionEntity(
            label: '1 portion $i',
            gramWeight: 100,
            localized: false,
          ),
      ]);

  static const potatoNfs = 2709382;
  static const potatoFrenchFriesFastFood = 2709461;
  static const potatoCookedAsIngredient = 2710790;

  /// What the resolver logs for `potato` on [potatoSearch]: titled
  /// "Stewed", with `potatoes` behind the title, at 0.5.
  static const stewedBeefWithPotatoes = 2706479;

  static const breadPita = 2707616;
  static const breadNaan = 2707613;
  static const breadWhite = 2707598;

  /// Not in [breadSearch]: rank 157 of the 540 rows `bread` matches.
  static const breadRye = 2707755;

  /// Deliverable portions per potato row. "Potato, NFS" carries 4; the
  /// two fast-food and restaurant french fries carry 12 each, the most in
  /// the family — FDC counts fries in more ways than a potato, which is
  /// what made "most portions first" the wrong key over the large families
  /// (#1170). Only "Potato, cooked, as ingredient" carries none, which is
  /// why it closes the pool.
  static const potatoPortions = <int, int>{
    2709382: 4,
    2709383: 4,
    2709384: 4,
    2709385: 6,
    2709386: 6,
    2709387: 6,
    2709388: 6,
    2709389: 6,
    2709390: 6,
    2709391: 6,
    2709392: 6,
    2709393: 6,
    2709394: 6,
    2709395: 6,
    2709396: 6,
    2709397: 6,
    2709398: 6,
    2709399: 2,
    2709400: 2,
    2709401: 2,
    2709402: 6,
    2709403: 6,
    2709404: 6,
    2709405: 6,
    2709406: 6,
    2709407: 6,
    2709408: 6,
    2709409: 6,
    2709410: 6,
    2709411: 6,
    2709412: 6,
    2709413: 6,
    2709414: 6,
    2709415: 6,
    2709448: 1,
    2709449: 1,
    2709450: 1,
    2709451: 1,
    2709452: 1,
    2709453: 1,
    2709454: 1,
    2709455: 1,
    2709456: 7,
    2709457: 7,
    2709458: 7,
    2709459: 7,
    2709460: 7,
    2709461: 12,
    2709462: 12,
    2709463: 7,
    2709464: 2,
    2709465: 7,
    2709466: 2,
    2709467: 7,
    2709468: 7,
    2709469: 2,
    2709470: 2,
    2709471: 2,
    2709472: 2,
    2709473: 1,
    2709474: 2,
    2709475: 1,
    2709476: 2,
    2709477: 2,
    2709478: 2,
    2709479: 2,
    2709480: 2,
    2709481: 2,
    2709482: 2,
    2709483: 1,
    2709484: 1,
    2709485: 1,
    2709486: 2,
    2709487: 2,
    2709492: 2,
    2709493: 1,
    2709494: 1,
    2709495: 1,
    2709496: 1,
    2709497: 2,
    2709498: 2,
    2709499: 2,
    2709500: 1,
    2709501: 1,
    2709502: 1,
    2709503: 1,
    2709504: 1,
    2709505: 1,
    2709506: 1,
    2709507: 1,
    2709508: 1,
    2709509: 1,
    2709518: 4,
    2709519: 4,
    2709520: 4,
    2709521: 4,
    2709522: 4,
    2709523: 4,
    2709524: 4,
    2709525: 4,
    2709526: 4,
    2709527: 4,
    2709528: 4,
    2709529: 4,
    2709530: 4,
    2710790: 0,
  };

  static bool potatoHasPortion(int id) => potatoPortions[id]! > 0;

  /// The 106 survey records titled "Potato", in the backend's pool order.
  static List<SpFoodDTO> get potato => [
    _survey(2709382, 'Potato, NFS'),
    _survey(2709383, 'Potato, baked, NFS'),
    _survey(2709384, 'Potato, baked, peel not eaten'),
    _survey(2709385, 'Potato, boiled, NFS'),
    _survey(2709386, 'Potato, boiled, ready-to-heat'),
    _survey(
      2709387,
      'Potato, boiled, from fresh, peel not eaten, NS as to fat',
    ),
    _survey(
      2709388,
      'Potato, boiled, from fresh, peel not eaten, no added fat',
    ),
    _survey(
      2709389,
      'Potato, boiled, from fresh, peel not eaten, fat added, NS as to fat type',
    ),
    _survey(
      2709390,
      'Potato, boiled, from fresh, peel not eaten, made with oil',
    ),
    _survey(
      2709391,
      'Potato, boiled, from fresh, peel not eaten, made with butter',
    ),
    _survey(
      2709392,
      'Potato, boiled, from fresh, peel not eaten, made with margarine',
    ),
    _survey(2709393, 'Potato, boiled, from fresh, peel eaten, NS as to fat'),
    _survey(
      2709394,
      'Potato, boiled, from fresh, peel eaten, fat added, NS as to fat type',
    ),
    _survey(2709395, 'Potato, boiled, from fresh,  peel eaten, no added fat'),
    _survey(2709396, 'Potato, boiled, from fresh, peel eaten, made with oil'),
    _survey(
      2709397,
      'Potato, boiled, from fresh, peel eaten, made with butter',
    ),
    _survey(
      2709398,
      'Potato, boiled, from fresh, peel eaten, made with margarine',
    ),
    _survey(2709399, 'Potato, canned, NS as to fat'),
    _survey(2709400, 'Potato, canned, fat added, NS as to fat type'),
    _survey(2709401, 'Potato, canned, no added fat'),
    _survey(2709402, 'Potato, roasted, NFS'),
    _survey(2709403, 'Potato, roasted, from fresh, peel eaten, NS as to fat'),
    _survey(2709404, 'Potato, roasted, from fresh, peel eaten, no added fat'),
    _survey(
      2709405,
      'Potato, roasted, from fresh, peel eaten, fat added, NS as to fat type',
    ),
    _survey(2709406, 'Potato, roasted, from fresh, peel eaten, made with oil'),
    _survey(
      2709407,
      'Potato, roasted, from fresh, peel eaten, made with butter',
    ),
    _survey(
      2709408,
      'Potato, roasted, from fresh, peel eaten, made with margarine',
    ),
    _survey(
      2709409,
      'Potato, roasted, from fresh, peel not eaten, NS as to fat',
    ),
    _survey(
      2709410,
      'Potato, roasted, from fresh, peel not eaten, fat added, NS as to fat type',
    ),
    _survey(
      2709411,
      'Potato, roasted, from fresh, peel not eaten, no added fat',
    ),
    _survey(
      2709412,
      'Potato, roasted, from fresh, peel not eaten, made with oil',
    ),
    _survey(
      2709413,
      'Potato, roasted, from fresh, peel not eaten, made with butter',
    ),
    _survey(
      2709414,
      'Potato, roasted, from fresh, peel not eaten, made with margarine',
    ),
    _survey(2709415, 'Potato, roasted, ready-to-heat'),
    _survey(2709448, 'Potato, scalloped, NFS'),
    _survey(2709449, 'Potato, scalloped, from fast food or restaurant'),
    _survey(2709450, 'Potato, scalloped, from fresh'),
    _survey(2709451, 'Potato, scalloped, from fresh, with meat'),
    _survey(2709452, 'Potato, scalloped, from dry mix'),
    _survey(2709453, 'Potato, scalloped, from dry mix, with meat'),
    _survey(2709454, 'Potato, scalloped, ready-to-heat'),
    _survey(2709455, 'Potato, scalloped, ready-to-heat, with meat'),
    _survey(2709456, 'Potato, french fries, NFS'),
    _survey(2709457, 'Potato, french fries, NS as to fresh or frozen'),
    _survey(2709458, 'Potato, french fries, from fresh, fried'),
    _survey(2709459, 'Potato, french fries, from fresh, baked'),
    _survey(2709460, 'Potato, french fries, from frozen, baked'),
    _survey(2709461, 'Potato, french fries, fast food'),
    _survey(2709462, 'Potato, french fries, restaurant'),
    _survey(2709463, 'Potato, french fries, from frozen, fried'),
    _survey(2709464, 'Potato, french fries, school'),
    _survey(
      2709465,
      'Potato, french fries, with cheese, fast food / restaurant',
    ),
    _survey(2709466, 'Potato, french fries, with cheese, school'),
    _survey(
      2709467,
      'Potato, french fries, with chili, fast food / restaurant',
    ),
    _survey(
      2709468,
      'Potato, french fries, with chili and cheese, fast food / restaurant',
    ),
    _survey(2709469, 'Potato, french fries, with cheese'),
    _survey(2709470, 'Potato, french fries, with chili and cheese'),
    _survey(2709471, 'Potato, french fries, with chili'),
    _survey(2709472, 'Potato, home fries, NFS'),
    _survey(2709473, 'Potato, home fries, from restaurant / fast food'),
    _survey(2709474, 'Potato, home fries, from fresh'),
    _survey(2709475, 'Potato, home fries, ready-to-heat'),
    _survey(2709476, 'Potato, home fries, with vegetables'),
    _survey(2709477, 'Potato, hash brown, NFS'),
    _survey(2709478, 'Potato, hash brown, from fast food'),
    _survey(2709479, 'Potato, hash brown, from fast food, with cheese'),
    _survey(2709480, 'Potato, hash brown, from restaurant'),
    _survey(2709481, 'Potato, hash brown, from restaurant, with cheese'),
    _survey(2709482, 'Potato, hash brown, from school lunch'),
    _survey(2709483, 'Potato, hash brown, from fresh'),
    _survey(2709484, 'Potato, hash brown, from fresh, with cheese'),
    _survey(2709485, 'Potato, hash brown, from dry mix'),
    _survey(2709486, 'Potato, hash brown, ready-to-heat'),
    _survey(2709487, 'Potato, hash brown, ready-to-heat, with cheese'),
    _survey(2709492, 'Potato, mashed, NFS'),
    _survey(2709493, 'Potato, mashed, from fast food'),
    _survey(2709494, 'Potato, mashed, from fast food, with gravy'),
    _survey(2709495, 'Potato, mashed, ready-to-heat'),
    _survey(2709496, 'Potato, mashed, from fresh, made with milk'),
    _survey(2709497, 'Potato, mashed, from fresh, made with milk, with cheese'),
    _survey(2709498, 'Potato, mashed, from fresh, made with milk, with gravy'),
    _survey(2709499, 'Potato, mashed, from fresh, NFS'),
    _survey(2709500, 'Potato, mashed, from restaurant'),
    _survey(2709501, 'Potato, mashed, from restaurant, with gravy'),
    _survey(2709502, 'Potato, mashed, from school lunch'),
    _survey(2709503, 'Potato, mashed, from dry mix, NFS'),
    _survey(2709504, 'Potato, mashed, from dry mix, made with milk'),
    _survey(
      2709505,
      'Potato, mashed, from dry mix, made with milk, with cheese',
    ),
    _survey(
      2709506,
      'Potato, mashed, from dry mix, made with milk, with gravy',
    ),
    _survey(2709507, 'Potato, mashed, ready-to-heat, NFS'),
    _survey(2709508, 'Potato, mashed, ready-to-heat, with cheese'),
    _survey(2709509, 'Potato, mashed, ready-to-heat, with gravy'),
    _survey(2709518, 'Potato, baked, peel not eaten, with butter'),
    _survey(2709519, 'Potato, baked, peel not eaten, with sour cream'),
    _survey(2709520, 'Potato, baked, peel not eaten, with cheese'),
    _survey(2709521, 'Potato, baked, peel not eaten, with meat'),
    _survey(2709522, 'Potato, baked, peel not eaten, with chili'),
    _survey(2709523, 'Potato, baked, peel not eaten, with vegetables'),
    _survey(2709524, 'Potato, baked, peel eaten'),
    _survey(2709525, 'Potato, baked, peel eaten, with butter'),
    _survey(2709526, 'Potato, baked, peel eaten, with sour cream'),
    _survey(2709527, 'Potato, baked, peel eaten, with cheese'),
    _survey(2709528, 'Potato, baked, peel eaten, with meat'),
    _survey(2709529, 'Potato, baked, peel eaten, with chili'),
    _survey(2709530, 'Potato, baked, peel eaten, with vegetables'),
    _survey(2710790, 'Potato, cooked, as ingredient'),
  ];

  /// Deliverable portions per row of [potatoSearch]: one or two each.
  static const potatoSearchPortions = <int, int>{
    2706474: 1,
    2706475: 2,
    2706478: 1,
    2706479: 1,
    2706503: 1,
    2706516: 1,
    2706517: 1,
    2706522: 1,
    2706523: 1,
    2706528: 1,
    2706585: 1,
    2706586: 1,
    2706587: 1,
    2706588: 1,
    2706589: 1,
    2706590: 1,
    2706595: 1,
    2706596: 1,
    2706597: 1,
    2706598: 1,
    2706599: 1,
    2706600: 1,
    2706601: 1,
    2706602: 1,
    2706603: 1,
    2706604: 1,
    2706637: 1,
    2706641: 1,
    2706642: 1,
    2706643: 1,
    2706644: 1,
    2706645: 1,
    2706646: 1,
    2706647: 1,
    2706653: 1,
    2706654: 1,
    2706662: 1,
    2706663: 1,
    2706666: 1,
    2706667: 1,
    2706668: 1,
    2706669: 1,
    2706670: 1,
    2706671: 1,
    2706672: 1,
    2706673: 1,
    2706674: 1,
    2706675: 1,
    2706676: 1,
    2706725: 1,
    2706728: 1,
    2706729: 1,
    2706730: 2,
    2706731: 1,
    2706734: 1,
    2706735: 1,
    2706736: 1,
    2706737: 1,
    2706739: 1,
    2706744: 1,
    2706745: 1,
    2706752: 1,
    2706753: 1,
    2706758: 1,
    2706760: 1,
    2706767: 1,
    2706768: 1,
    2706769: 1,
    2706770: 1,
    2706772: 1,
    2706773: 1,
    2706774: 1,
    2706775: 1,
    2706777: 1,
    2706778: 1,
    2706779: 2,
    2706780: 2,
    2706781: 1,
    2706782: 1,
    2706783: 2,
    2706785: 1,
    2706786: 1,
    2706787: 2,
    2706788: 1,
    2706790: 1,
    2706791: 1,
    2706792: 1,
    2706793: 1,
    2706820: 1,
    2706821: 1,
    2706822: 1,
    2706823: 1,
    2706851: 1,
    2706852: 1,
    2706853: 1,
    2706854: 1,
    2706855: 2,
    2706859: 1,
    2706860: 1,
    2706861: 1,
  };

  /// `search_food_summary('potato', null, 100)` as it answered: the hundred
  /// rows the app is handed for `potato`, in the function's order. Every
  /// short title is a dish; none is "Potato".
  static List<SpFoodDTO> get potatoSearch => [
    _found(2706474, 'Beef and potatoes, no sauce', title: 'Beef and potatoes'),
    _found(
      2706475,
      'Beef and potatoes with cream sauce, white sauce or mushroom sauce',
      title: 'Beef and potatoes with cream sauce',
    ),
    _found(
      2706478,
      'Beef and potatoes with cheese sauce',
      title: 'Beef and potatoes with cheese sauce',
    ),
    _found(
      2706479,
      'Stewed, seasoned, ground beef with potatoes, Mexican style',
      title: 'Stewed',
    ),
    _found(
      2706503,
      'Beef stew with potatoes, Puerto Rican style',
      title: 'Beef stew with potatoes',
    ),
    _found(
      2706516,
      'Ham or pork and potatoes with gravy',
      title: 'Ham or pork and potatoes with gravy',
    ),
    _found(
      2706517,
      'Ham or pork and potatoes with cheese sauce',
      title: 'Ham or pork and potatoes with cheese sauce',
    ),
    _found(
      2706522,
      'Lamb or mutton and potatoes with gravy',
      title: 'Lamb or mutton and potatoes with gravy',
    ),
    _found(
      2706523,
      'Lamb or mutton and potatoes with tomato-based sauce',
      title: 'Lamb or mutton and potatoes with tomato-based sauce',
    ),
    _found(
      2706528,
      'Chicken or turkey and potatoes with gravy',
      title: 'Chicken or turkey and potatoes with gravy',
    ),
    _found(
      2706585,
      'Vienna sausages stewed with potatoes, Puerto Rican style',
      title: 'Vienna sausages stewed with potatoes',
    ),
    _found(
      2706586,
      'Stewed, seasoned, ground beef and pork with potatoes, Mexican style',
      title: 'Stewed',
    ),
    _found(
      2706587,
      'Beef, potatoes, and vegetables including carrots, broccoli, and/or dark-green leafy; no sauce',
      title: 'Beef',
    ),
    _found(
      2706588,
      'Beef, potatoes, and vegetables, excluding carrots, broccoli, and dark-green leafy; no sauce',
      title: 'Beef',
    ),
    _found(
      2706589,
      'Corned beef, potatoes, and vegetables including carrots, broccoli, and/or dark-green leafy; no sauce',
      title: 'Corned beef',
    ),
    _found(
      2706590,
      'Corned beef, potatoes, and vegetables excluding carrots, broccoli, and dark-green leafy; no sauce',
      title: 'Corned beef',
    ),
    _found(
      2706595,
      'Beef, potatoes, and vegetables including carrots, broccoli, and/or dark-green leafy; gravy',
      title: 'Beef',
    ),
    _found(
      2706596,
      'Beef, potatoes, and vegetables excluding carrots, broccoli, and dark-green leafy; gravy',
      title: 'Beef',
    ),
    _found(
      2706597,
      'Beef, potatoes, and vegetables including carrots, broccoli, and/or dark-green leafy; cream sauce, white sauce, or mushroom sauce',
      title: 'Beef',
    ),
    _found(
      2706598,
      'Beef, potatoes, and vegetables excluding carrots, broccoli, and dark-green leafy; cream sauce, white sauce, or mushroom sauce',
      title: 'Beef',
    ),
    _found(
      2706599,
      'Beef, potatoes, and vegetables including carrots, broccoli, and/or dark-green leafy; tomato-based sauce',
      title: 'Beef',
    ),
    _found(
      2706600,
      'Beef, potatoes, and vegetables excluding carrots, broccoli, and dark-green leafy; tomato-based sauce',
      title: 'Beef',
    ),
    _found(
      2706601,
      'Beef, potatoes, and vegetables including carrots, broccoli, and/or dark-green leafy; cheese sauce',
      title: 'Beef',
    ),
    _found(
      2706602,
      'Beef, potatoes, and vegetables excluding carrots, broccoli, and dark-green leafy; cheese sauce',
      title: 'Beef',
    ),
    _found(
      2706603,
      'Beef, potatoes, and vegetables including carrots, broccoli, and/or dark-green leafy; soy-based sauce',
      title: 'Beef',
    ),
    _found(
      2706604,
      'Beef, potatoes, and vegetables excluding carrots, broccoli, and dark-green leafy; soy-based sauce',
      title: 'Beef',
    ),
    _found(
      2706637,
      'Pork, potatoes, and vegetables including carrots, broccoli, and/or dark-green leafy; no sauce',
      title: 'Pork',
    ),
    _found(
      2706641,
      'Pork, potatoes, and vegetables including carrots, broccoli, and/or dark-green leafy; tomato-based sauce',
      title: 'Pork',
    ),
    _found(
      2706642,
      'Pork, potatoes, and vegetables excluding carrots, broccoli, and dark-green leafy; tomato-based sauce',
      title: 'Pork',
    ),
    _found(
      2706643,
      'Sausage, potatoes, and vegetables including carrots, broccoli, and/or dark-green leafy; gravy',
      title: 'Sausage',
    ),
    _found(
      2706644,
      'Sausage, potatoes, and vegetables excluding carrots, broccoli, and dark-green leafy; gravy',
      title: 'Sausage',
    ),
    _found(
      2706645,
      'Pork, potatoes, and vegetables including carrots, broccoli, and/or dark-green leafy; gravy',
      title: 'Pork',
    ),
    _found(
      2706646,
      'Pork, potatoes, and vegetables excluding carrots, broccoli, and dark-green leafy; gravy',
      title: 'Pork',
    ),
    _found(
      2706647,
      'Pork, potatoes, and vegetables excluding carrots, broccoli, and dark-green leafy; no sauce',
      title: 'Pork',
    ),
    _found(
      2706653,
      'Ham, potatoes, and vegetables excluding carrots, broccoli, and dark-green leafy; no sauce',
      title: 'Ham',
    ),
    _found(
      2706654,
      'Ham, potatoes, and vegetables including carrots, broccoli, and/or dark-green leafy; no sauce',
      title: 'Ham',
    ),
    _found(
      2706662,
      'Venison or deer, potatoes, and vegetables including carrots, broccoli, and/or dark-green leafy; gravy',
      title: 'Venison or deer',
    ),
    _found(
      2706663,
      'Venison or deer, potatoes, and vegetables excluding carrots, broccoli, and dark-green leafy; gravy',
      title: 'Venison or deer',
    ),
    _found(
      2706666,
      'Chicken or turkey, potatoes, corn, and cheese, with gravy',
      title: 'Chicken or turkey',
    ),
    _found(
      2706667,
      'Chicken or turkey, potatoes, and vegetables including carrots, broccoli, and/or dark-green leafy; no sauce',
      title: 'Chicken or turkey',
    ),
    _found(
      2706668,
      'Chicken or turkey, potatoes, and vegetables excluding carrots, broccoli, and dark-green leafy; no sauce',
      title: 'Chicken or turkey',
    ),
    _found(
      2706669,
      'Chicken or turkey, potatoes, and vegetables including carrots, broccoli, and/or dark-green leafy; gravy',
      title: 'Chicken or turkey',
    ),
    _found(
      2706670,
      'Chicken or turkey, potatoes, and vegetables excluding carrots, broccoli, and dark-green leafy; gravy',
      title: 'Chicken or turkey',
    ),
    _found(
      2706671,
      'Chicken or turkey, potatoes, and vegetables including carrots, broccoli, and/or dark-green leafy; cream sauce, white sauce, or mushroom sauce',
      title: 'Chicken or turkey',
    ),
    _found(
      2706672,
      'Chicken or turkey, potatoes, and vegetables excluding carrots, broccoli, and dark-green leafy; cream sauce, white sauce, or mushroom sauce',
      title: 'Chicken or turkey',
    ),
    _found(
      2706673,
      'Chicken or turkey, potatoes, and vegetables including carrots, broccoli, and/or dark-green leafy; cheese sauce',
      title: 'Chicken or turkey',
    ),
    _found(
      2706674,
      'Chicken or turkey, potatoes, and vegetables excluding carrots, broccoli, and dark-green leafy; cheese sauce',
      title: 'Chicken or turkey',
    ),
    _found(
      2706675,
      'Chicken or turkey, potatoes, and vegetables including carrots, broccoli, and/or dark-green leafy; tomato-based sauce',
      title: 'Chicken or turkey',
    ),
    _found(
      2706676,
      'Chicken or turkey, potatoes, and vegetables excluding carrots, broccoli, and dark-green leafy; tomato-based sauce',
      title: 'Chicken or turkey',
    ),
    _found(
      2706725,
      'Stewed tripe, with potatoes, Puerto Rican style',
      title: 'Stewed tripe',
    ),
    _found(
      2706728,
      'Beef and vegetables including carrots, broccoli, and/or dark-green leafy; no potatoes, no sauce',
      title: 'Beef and vegetables including carrots',
    ),
    _found(
      2706729,
      'Beef and vegetables excluding carrots, broccoli, and dark-green leafy; no potatoes, no sauce',
      title: 'Beef and vegetables excluding carrots',
    ),
    _found(
      2706730,
      'Beef shish kabob with vegetables, excluding potatoes',
      title: 'Beef shish kabob with vegetables',
    ),
    _found(
      2706731,
      'Beef with vegetables including carrots, broccoli, and/or dark-green leafy; no potatoes, tomato-based sauce',
      title: 'Beef with vegetables including carrots',
    ),
    _found(
      2706734,
      'Beef with vegetables excluding carrots, broccoli, and dark-green leafy; no potatoes, tomato-based sauce',
      title: 'Beef with vegetables excluding carrots',
    ),
    _found(
      2706735,
      'Beef with vegetables including carrots, broccoli, and/or dark-green leafy; no potatoes, mushroom sauce',
      title: 'Beef with vegetables including carrots',
    ),
    _found(
      2706736,
      'Beef with vegetables excluding carrots, broccoli, and dark-green leafy; no potatoes, mushroom sauce',
      title: 'Beef with vegetables excluding carrots',
    ),
    _found(
      2706737,
      'Beef and vegetables including carrots, broccoli, and/or dark-green leafy; no potatoes, soy-based sauce',
      title: 'Beef and vegetables including carrots',
    ),
    _found(
      2706739,
      'Beef, tofu, and vegetables including carrots, broccoli, and/or dark-green leafy; no potatoes, soy-based sauce',
      title: 'Beef',
    ),
    _found(
      2706744,
      'Beef and vegetables excluding carrots, broccoli, and dark-green leafy; no potatoes, soy-based sauce',
      title: 'Beef and vegetables excluding carrots',
    ),
    _found(
      2706745,
      'Beef, tofu, and vegetables excluding carrots, broccoli,  and dark-green leafy; no potatoes, soy-based sauce',
      title: 'Beef',
    ),
    _found(
      2706752,
      'Beef and vegetables including carrots, broccoli, and/or dark-green leafy; no potatoes, gravy',
      title: 'Beef and vegetables including carrots',
    ),
    _found(
      2706753,
      'Beef and vegetables excluding carrots, broccoli, and dark-green leafy; no potatoes, gravy',
      title: 'Beef and vegetables excluding carrots',
    ),
    _found(
      2706758,
      'Pork and vegetables including carrots, broccoli, and/or dark-green leafy; no potatoes, no sauce',
      title: 'Pork and vegetables including carrots',
    ),
    _found(
      2706760,
      'Pork, tofu, and vegetables including carrots, broccoli, and/or dark-green leafy; no potatoes, soy-base sauce',
      title: 'Pork',
    ),
    _found(
      2706767,
      'Ham and vegetables including carrots broccoli, and/or dark- green leafy; no potatoes, no sauce',
      title: 'Ham and vegetables including carrots broccoli',
    ),
    _found(
      2706768,
      'Ham and vegetables excluding carrots, broccoli, and dark-green leafy; no potatoes, no sauce',
      title: 'Ham and vegetables excluding carrots',
    ),
    _found(
      2706769,
      'Pork and vegetables excluding carrots, broccoli, and dark-green leafy; no potatoes, no sauce',
      title: 'Pork and vegetables excluding carrots',
    ),
    _found(
      2706770,
      'Pork, tofu, and vegetables, excluding carrots, broccoli, and dark-green leafy; no potatoes, soy-based sauce',
      title: 'Pork',
    ),
    _found(
      2706772,
      'Pork and vegetables including carrots, broccoli, and/or dark-green leafy; no potatoes, tomato-based sauce',
      title: 'Pork and vegetables including carrots',
    ),
    _found(
      2706773,
      'Pork and vegetables excluding  carrots, broccoli, and dark-green leafy; no potatoes, tomato-based sauce',
      title: 'Pork and vegetables excluding  carrots',
    ),
    _found(
      2706774,
      'Sausage and vegetables including  carrots, broccoli, and/or dark-green leafy; no potatoes, tomato-based sauce',
      title: 'Sausage and vegetables including  carrots',
    ),
    _found(
      2706775,
      'Sausage and vegetables, excluding carrots, broccoli, and dark-green leafy; no potatoes, tomato-based sauce',
      title: 'Sausage and vegetables',
    ),
    _found(
      2706777,
      'Pork and vegetables including carrots, broccoli, and/or dark-green leafy; no potatoes, soy-based sauce',
      title: 'Pork and vegetables including carrots',
    ),
    _found(
      2706778,
      'Pork and vegetables excluding carrots, broccoli, and dark- green leafy; no potatoes, soy-based sauce',
      title: 'Pork and vegetables excluding carrots',
    ),
    _found(
      2706779,
      'Pork shish kabob with vegetables, excluding potatoes',
      title: 'Pork shish kabob with vegetables',
    ),
    _found(
      2706780,
      'Lamb shish kabob with vegetables, excluding potatoes',
      title: 'Lamb shish kabob with vegetables',
    ),
    _found(
      2706781,
      'Chicken or turkey and vegetables including carrots, broccoli, and/or dark-green leafy; no potatoes, no sauce',
      title: 'Chicken or turkey and vegetables including carrots',
    ),
    _found(
      2706782,
      'Chicken or turkey and vegetables excluding carrots, broccoli, and dark-green leafy; no potatoes, no sauce',
      title: 'Chicken or turkey and vegetables excluding carrots',
    ),
    _found(
      2706783,
      'Chicken or turkey shish kabob with vegetables, excluding potatoes',
      title: 'Chicken or turkey shish kabob with vegetables',
    ),
    _found(
      2706785,
      'Chicken or turkey and vegetables including carrots, broccoli, and/or dark-green leafy; no potatoes, gravy',
      title: 'Chicken or turkey and vegetables including carrots',
    ),
    _found(
      2706786,
      'Chicken or turkey and vegetables excluding carrots, broccoli, and dark-green leafy; no potatoes, gravy',
      title: 'Chicken or turkey and vegetables excluding carrots',
    ),
    _found(
      2706787,
      'Chicken or turkey a la king with vegetables including carrots, broccoli, and/or dark-green leafy; no potatoes, cream, white, or soup-based sauce',
      title: 'Chicken or turkey a la king with vegetables including carrots',
    ),
    _found(
      2706788,
      'Chicken or turkey a la king with vegetables excluding carrorts, broccoli, and dark-green leafy; no potatoes, cream, white, or soup-based sauce',
      title: 'Chicken or turkey a la king with vegetables excluding carrorts',
    ),
    _found(
      2706790,
      'Chicken or turkey and vegetables including carrots, broccoli, and/or dark-green leafy; no potatoes, soy-based sauce',
      title: 'Chicken or turkey and vegetables including carrots',
    ),
    _found(
      2706791,
      'Chicken or turkey and vegetables excluding carrots, broccoli, and dark-green leafy; no potatoes, soy-based sauce',
      title: 'Chicken or turkey and vegetables excluding carrots',
    ),
    _found(
      2706792,
      'Chicken or turkey and vegetables including carrots, broccoli, and/or dark-green leafy; no potatoes, tomato-based sauce',
      title: 'Chicken or turkey and vegetables including carrots',
    ),
    _found(
      2706793,
      'Chicken or turkey and vegetables excluding carrots, broccoli, and dark-green leafy; no potatoes, tomato-based sauce',
      title: 'Chicken or turkey and vegetables excluding carrots',
    ),
    _found(
      2706820,
      'Chicken or turkey and vegetables including carrots, broccoli, and/or dark-green leafy; no potatoes, cheese sauce',
      title: 'Chicken or turkey and vegetables including carrots',
    ),
    _found(
      2706821,
      'Chicken or turkey and vegetables excluding carrots, broccoli, and dark-green leafy; no potatoes, cheese sauce',
      title: 'Chicken or turkey and vegetables excluding carrots',
    ),
    _found(
      2706822,
      'Chicken or turkey fricassee, with sauce, no potatoes, potatoes reported separately, Puerto Rican style',
      title: 'Chicken or turkey fricassee',
    ),
    _found(
      2706823,
      'Chicken or turkey fricassee, no sauce, no potatoes, Puerto Rican style',
      title: 'Chicken or turkey fricassee',
    ),
    _found(
      2706851,
      'Shrimp and vegetables including carrots, broccoli, and/or dark-green leafy; no potatoes, no sauce',
      title: 'Shrimp and vegetables including carrots',
    ),
    _found(
      2706852,
      'Shrimp and vegetables excluding carrots, broccoli, and dark-green leafy; no potatoes, no sauce',
      title: 'Shrimp and vegetables excluding carrots',
    ),
    _found(
      2706853,
      'Shrimp and vegetables including carrots, broccoli, and/or dark-green leafy; no potatoes, soy-based sauce',
      title: 'Shrimp and vegetables including carrots',
    ),
    _found(
      2706854,
      'Shrimp and vegetables excluding carrots, broccoli, and dark-green leafy; no potatoes, soy-based sauce',
      title: 'Shrimp and vegetables excluding carrots',
    ),
    _found(
      2706855,
      'Shrimp shish kabob with vegetables, excluding potatoes',
      title: 'Shrimp shish kabob with vegetables',
    ),
    _found(
      2706859,
      'Shellfish mixture and vegetables including carrots, broccoli, and/or dark-green leafy; no potatoes, soy-based sauce',
      title: 'Shellfish mixture and vegetables including carrots',
    ),
    _found(
      2706860,
      'Shellfish mixture and vegetables excluding carrots, broccoli, and dark-green leafy; no potatoes, soy-based sauce',
      title: 'Shellfish mixture and vegetables excluding carrots',
    ),
    _found(
      2706861,
      'Shellfish mixture and vegetables including carrots, broccoli, and/or dark-green leafy; no potatoes, mushroom sauce',
      title: 'Shellfish mixture and vegetables including carrots',
    ),
  ];

  /// Deliverable portions per row of [breadSearch]. "Bread, pita" carries
  /// 5 and "Bread, naan" 3 — eleven characters each, so the portions key
  /// is what puts pita first — and "Bread, white" 7, at twelve.
  static const breadSearchPortions = <int, int>{
    2705680: 2,
    2705795: 1,
    2705796: 1,
    2705797: 1,
    2705798: 1,
    2705799: 1,
    2705800: 1,
    2705802: 1,
    2705803: 1,
    2705804: 1,
    2705805: 1,
    2705806: 1,
    2705807: 1,
    2705817: 4,
    2706088: 2,
    2706089: 2,
    2706099: 4,
    2706100: 3,
    2706101: 4,
    2706102: 5,
    2706103: 3,
    2706107: 5,
    2706108: 5,
    2706563: 1,
    2706580: 2,
    2706813: 4,
    2706815: 3,
    2706819: 2,
    2707058: 1,
    2707059: 1,
    2707062: 1,
    2707063: 1,
    2707066: 1,
    2707067: 1,
    2707070: 1,
    2707071: 1,
    2707074: 1,
    2707075: 1,
    2707077: 1,
    2707080: 1,
    2707081: 1,
    2707107: 1,
    2707192: 2,
    2707307: 4,
    2707308: 4,
    2707309: 4,
    2707310: 4,
    2707311: 4,
    2707312: 4,
    2707313: 4,
    2707314: 4,
    2707449: 2,
    2707469: 3,
    2707550: 2,
    2707551: 2,
    2707552: 2,
    2707553: 2,
    2707555: 2,
    2707556: 2,
    2707557: 2,
    2707558: 2,
    2707559: 2,
    2707560: 2,
    2707562: 2,
    2707563: 2,
    2707564: 2,
    2707565: 2,
    2707566: 2,
    2707567: 2,
    2707591: 5,
    2707592: 5,
    2707593: 6,
    2707594: 5,
    2707598: 7,
    2707599: 7,
    2707600: 6,
    2707601: 5,
    2707602: 5,
    2707603: 5,
    2707604: 5,
    2707605: 4,
    2707606: 1,
    2707607: 1,
    2707608: 1,
    2707609: 1,
    2707610: 11,
    2707611: 8,
    2707613: 3,
    2707614: 8,
    2707615: 7,
    2707616: 5,
    2707617: 5,
    2707618: 6,
    2707619: 6,
    2707620: 5,
    2707621: 5,
    2707622: 5,
    2707623: 5,
    2707624: 5,
    2707625: 4,
  };

  /// `search_food_summary('bread', null, 100)` as it answered: the hundred
  /// rows the app is handed for `bread`, in the function's order.
  /// Thirty-one are titled "Bread"; "Bread, rye" is not among them.
  static List<SpFoodDTO> get breadSearch => [
    _found(2705680, 'Pudding, bread', title: 'Pudding'),
    _found(
      2705795,
      'Cheese sandwich, American cheese, on white bread',
      title: 'Cheese sandwich',
    ),
    _found(
      2705796,
      'Cheese sandwich, American cheese, on wheat bread',
      title: 'Cheese sandwich',
    ),
    _found(
      2705797,
      'Cheese sandwich, cheddar cheese, on white bread',
      title: 'Cheese sandwich',
    ),
    _found(
      2705798,
      'Cheese sandwich, cheddar cheese, on wheat bread',
      title: 'Cheese sandwich',
    ),
    _found(
      2705799,
      'Cheese sandwich, reduced fat cheese, on white bread',
      title: 'Cheese sandwich',
    ),
    _found(
      2705800,
      'Cheese sandwich, reduced fat cheese, on wheat bread',
      title: 'Cheese sandwich',
    ),
    _found(
      2705802,
      'Grilled cheese sandwich, American cheese, on white bread',
      title: 'Grilled cheese sandwich',
    ),
    _found(
      2705803,
      'Grilled cheese sandwich, American cheese, on wheat bread',
      title: 'Grilled cheese sandwich',
    ),
    _found(
      2705804,
      'Grilled cheese sandwich, cheddar cheese, on white bread',
      title: 'Grilled cheese sandwich',
    ),
    _found(
      2705805,
      'Grilled cheese sandwich, cheddar cheese, on wheat bread',
      title: 'Grilled cheese sandwich',
    ),
    _found(
      2705806,
      'Grilled cheese sandwich, reduced fat cheese, on white bread',
      title: 'Grilled cheese sandwich',
    ),
    _found(
      2705807,
      'Grilled cheese sandwich, reduced fat cheese, on wheat bread',
      title: 'Grilled cheese sandwich',
    ),
    _found(
      2705817,
      'Mozzarella sticks, breaded, baked, or fried',
      title: 'Mozzarella sticks',
    ),
    _found(2706088, 'Chicken patty, breaded', title: 'Chicken patty'),
    _found(2706089, 'Chicken fillet, breaded', title: 'Chicken fillet'),
    _found(
      2706099,
      'Chicken tenders or strips, breaded, from fast food',
      title: 'Chicken tenders or strips',
    ),
    _found(
      2706100,
      'Chicken tenders or strips, breaded, from restaurant',
      title: 'Chicken tenders or strips',
    ),
    _found(
      2706101,
      'Chicken tenders or strips, breaded, from school lunch',
      title: 'Chicken tenders or strips',
    ),
    _found(
      2706102,
      'Chicken tenders or strips, breaded, from frozen',
      title: 'Chicken tenders or strips',
    ),
    _found(
      2706103,
      'Chicken tenders or strips, breaded, from other sources',
      title: 'Chicken tenders or strips',
    ),
    _found(
      2706107,
      'Turkey, light meat, breaded, baked or fried, skin not eaten',
      title: 'Turkey',
    ),
    _found(
      2706108,
      'Turkey, light meat, breaded, baked or fried, skin eaten',
      title: 'Turkey',
    ),
    _found(
      2706563,
      'Lobster with bread stuffing, baked',
      title: 'Lobster with bread stuffing',
    ),
    _found(
      2706580,
      'Meatballs, with breading, NS as to type of meat, with gravy',
      title: 'Meatballs',
    ),
    _found(
      2706813,
      'Chicken or turkey, breaded, fried, garden salad with bacon and cheese, chicken and/or turkey, bacon, cheese, lettuce and/or greens, tomato and/or carrots, other vegetables, no dressing',
      title: 'Chicken or turkey',
    ),
    _found(
      2706815,
      'Chicken or turkey, breaded, fried, garden salad with cheese, chicken and/or turkey, cheese, lettuce and/or greens, tomato and/or carrots, other vegetables, no dressing',
      title: 'Chicken or turkey',
    ),
    _found(
      2706819,
      'Chicken or turkey, breaded, fried, caesar garden salad, chicken and/or turkey, lettuce, tomatoes, cheese, no dressing',
      title: 'Chicken or turkey',
    ),
    _found(
      2707058,
      'Hot dog sandwich, NFS, on white bread',
      title: 'Hot dog sandwich',
    ),
    _found(
      2707059,
      'Hot dog sandwich, NFS, on wheat bread',
      title: 'Hot dog sandwich',
    ),
    _found(
      2707062,
      'Hot dog sandwich, beef, on white bread',
      title: 'Hot dog sandwich',
    ),
    _found(
      2707063,
      'Hot dog sandwich, beef, on wheat bread',
      title: 'Hot dog sandwich',
    ),
    _found(
      2707066,
      'Hot dog sandwich, meat and poultry, on white bread',
      title: 'Hot dog sandwich',
    ),
    _found(
      2707067,
      'Hot dog sandwich, meat and poultry, on wheat bread',
      title: 'Hot dog sandwich',
    ),
    _found(
      2707070,
      'Hot dog sandwich, turkey, on white bread',
      title: 'Hot dog sandwich',
    ),
    _found(
      2707071,
      'Hot dog sandwich, turkey, on wheat bread',
      title: 'Hot dog sandwich',
    ),
    _found(
      2707074,
      'Hot dog sandwich, reduced fat, on white bread',
      title: 'Hot dog sandwich',
    ),
    _found(
      2707075,
      'Hot dog sandwich, reduced fat, on wheat bread',
      title: 'Hot dog sandwich',
    ),
    _found(
      2707077,
      'Hot dog sandwich, vegetarian, on bread',
      title: 'Hot dog sandwich',
    ),
    _found(
      2707080,
      'Chili hot dog sandwich, on white bread',
      title: 'Chili hot dog sandwich',
    ),
    _found(
      2707081,
      'Chili hot dog sandwich, on wheat bread',
      title: 'Chili hot dog sandwich',
    ),
    _found(
      2707107,
      'Chicken patty, or nuggets, boneless, breaded, potatoes, vegetable, frozen meal',
      title: 'Chicken patty',
    ),
    _found(
      2707192,
      'Egg casserole with bread, cheese, milk and meat',
      title: 'Egg casserole with bread',
    ),
    _found(
      2707307,
      'Egg sandwich on white bread',
      title: 'Egg sandwich on white bread',
    ),
    _found(
      2707308,
      'Egg sandwich on white bread, with cheese',
      title: 'Egg sandwich on white bread',
    ),
    _found(
      2707309,
      'Egg sandwich on white bread, with meat',
      title: 'Egg sandwich on white bread',
    ),
    _found(
      2707310,
      'Egg sandwich on white bread, with meat and cheese',
      title: 'Egg sandwich on white bread',
    ),
    _found(
      2707311,
      'Egg sandwich on wheat bread',
      title: 'Egg sandwich on wheat bread',
    ),
    _found(
      2707312,
      'Egg sandwich on wheat bread, with cheese',
      title: 'Egg sandwich on wheat bread',
    ),
    _found(
      2707313,
      'Egg sandwich on wheat bread, with meat',
      title: 'Egg sandwich on wheat bread',
    ),
    _found(
      2707314,
      'Egg sandwich on wheat bread, with meat and cheese',
      title: 'Egg sandwich on wheat bread',
    ),
    _found(2707449, 'Soybean curd, breaded, fried', title: 'Soybean curd'),
    _found(2707469, 'Chicken, meatless, breaded, fried', title: 'Chicken'),
    _found(
      2707550,
      'Peanut butter sandwich, with regular peanut butter, on white bread',
      title: 'Peanut butter sandwich',
    ),
    _found(
      2707551,
      'Peanut butter sandwich, with regular peanut butter, on wheat bread',
      title: 'Peanut butter sandwich',
    ),
    _found(
      2707552,
      'Peanut butter sandwich, with reduced fat peanut butter, on white bread',
      title: 'Peanut butter sandwich',
    ),
    _found(
      2707553,
      'Peanut butter sandwich, with reduced fat peanut butter, on wheat bread',
      title: 'Peanut butter sandwich',
    ),
    _found(
      2707555,
      'Peanut butter and jelly sandwich, with regular peanut butter, regular jelly, on white bread',
      title: 'Peanut butter and jelly sandwich',
    ),
    _found(
      2707556,
      'Peanut butter and jelly sandwich, with regular peanut butter, regular jelly, on wheat bread',
      title: 'Peanut butter and jelly sandwich',
    ),
    _found(
      2707557,
      'Peanut butter and jelly sandwich, with reduced fat peanut butter, on white bread',
      title: 'Peanut butter and jelly sandwich',
    ),
    _found(
      2707558,
      'Peanut butter and jelly sandwich, with reduced fat peanut butter, on wheat bread',
      title: 'Peanut butter and jelly sandwich',
    ),
    _found(
      2707559,
      'Peanut butter and jelly sandwich, with regular peanut butter, reduced sugar jelly, on white bread',
      title: 'Peanut butter and jelly sandwich',
    ),
    _found(
      2707560,
      'Peanut butter and jelly sandwich, with regular peanut butter, reduced sugar jelly, on wheat bread',
      title: 'Peanut butter and jelly sandwich',
    ),
    _found(
      2707562,
      'Almond butter sandwich, on white bread',
      title: 'Almond butter sandwich',
    ),
    _found(
      2707563,
      'Almond butter sandwich, on wheat bread',
      title: 'Almond butter sandwich',
    ),
    _found(
      2707564,
      'Almond butter and jelly sandwich, on white bread',
      title: 'Almond butter and jelly sandwich',
    ),
    _found(
      2707565,
      'Almond butter and jelly sandwich, on wheat bread',
      title: 'Almond butter and jelly sandwich',
    ),
    _found(
      2707566,
      'Nutella sandwich on white bread',
      title: 'Nutella sandwich on white bread',
    ),
    _found(
      2707567,
      'Nutella sandwich on wheat bread',
      title: 'Nutella sandwich on wheat bread',
    ),
    _found(2707591, 'Bread, NS as to major flour', title: 'Bread'),
    _found(2707592, 'Bread, NS as to major flour, toasted', title: 'Bread'),
    _found(
      2707593,
      'Bread, made from home recipe or purchased at a bakery, NS as to major flour',
      title: 'Bread',
    ),
    _found(
      2707594,
      'Bread, made from home recipe or purchased at a bakery, toasted, NS as to major flour',
      title: 'Bread',
    ),
    _found(2707598, 'Bread, white', title: 'Bread'),
    _found(2707599, 'Bread, white, toasted', title: 'Bread'),
    _found(
      2707600,
      'Bread, white, made from home recipe or purchased at a bakery',
      title: 'Bread',
    ),
    _found(
      2707601,
      'Bread, white, made from home recipe or purchased at a bakery, toasted',
      title: 'Bread',
    ),
    _found(2707602, 'Bread, white with whole wheat swirl', title: 'Bread'),
    _found(
      2707603,
      'Bread, white with whole wheat swirl, toasted',
      title: 'Bread',
    ),
    _found(2707604, 'Bread, Cuban', title: 'Bread'),
    _found(2707605, 'Bread, Cuban, toasted', title: 'Bread'),
    _found(2707606, 'Bread, native, water, Puerto Rican style', title: 'Bread'),
    _found(
      2707607,
      'Bread, native, water, toasted, Puerto Rican style',
      title: 'Bread',
    ),
    _found(2707608, 'Bread, lard, Puerto Rican style', title: 'Bread'),
    _found(2707609, 'Bread, lard, toasted, Puerto Rican style', title: 'Bread'),
    _found(2707610, 'Bread, French or Vienna', title: 'Bread'),
    _found(2707611, 'Bread, French or Vienna, toasted', title: 'Bread'),
    _found(2707613, 'Bread, naan', title: 'Bread'),
    _found(2707614, 'Bread, Italian, Grecian, Armenian', title: 'Bread'),
    _found(
      2707615,
      'Bread, Italian, Grecian, Armenian, toasted',
      title: 'Bread',
    ),
    _found(2707616, 'Bread, pita', title: 'Bread'),
    _found(2707617, 'Bread, pita with fruit', title: 'Bread'),
    _found(2707618, 'Bread, cheese', title: 'Bread'),
    _found(2707619, 'Bread, cheese, toasted', title: 'Bread'),
    _found(2707620, 'Bread, cinnamon', title: 'Bread'),
    _found(2707621, 'Bread, cinnamon, toasted', title: 'Bread'),
    _found(2707622, 'Bread, cornmeal and molasses', title: 'Bread'),
    _found(2707623, 'Bread, cornmeal and molasses, toasted', title: 'Bread'),
    _found(2707624, 'Bread, egg, Challah', title: 'Bread'),
    _found(2707625, 'Bread, egg, Challah, toasted', title: 'Bread'),
  ];

  static Map<String, dynamic> _translation(int foodId, String description) => {
    SPConst.translationFoodId: foodId,
    SPConst.translationDescription: description,
    SPConst.translationSource: SPConst.translationSourceMachine,
  };

  /// The 100 German `food_translation` rows for `Milch`, in the backend's
  /// pool order. Every one is a machine translation.
  static List<Map<String, dynamic>> get milch => [
    _translation(2705383, 'Milch, menschliche'),
    _translation(2705384, 'Milch, NFS'),
    _translation(2705386, 'Milch, fettarm (2 %)'),
    _translation(2705387, 'Milch, fettarm (1 %)'),
    _translation(2705388, 'Milch, fettfrei (Magermilch)'),
    _translation(2705389, 'Milch, laktosefrei, fettarm (1 %)'),
    _translation(2705390, 'Milch, laktosefrei, fettfrei (Magermilch)'),
    _translation(2705391, 'Milch, laktosefrei, fettarm (2 %)'),
    _translation(2705392, 'Milch, laktosefrei, Vollmilch'),
    _translation(
      2705396,
      'Milch, Trockenmilch, rekonstituierte Milch, fettfreie Milch',
    ),
    _translation(
      2705397,
      'Milch, Trockenmilch, rekonstituierte Milch, Vollmilch',
    ),
    _translation(2705399, 'Milch, Kondensmilch, Vollmilch'),
    _translation(2705401, 'Milch, eingedampft, fettfrei (Magermilch)'),
    _translation(2705402, 'Milch, kondensiert, gesüßt'),
    _translation(2705419, 'Joghurt, fettarme Milch, Natur'),
    _translation(2705420, 'Joghurt, fettfreie Milch, Natur'),
    _translation(
      2705423,
      'Joghurt, griechischer Joghurt, fettarme Milch, Naturjoghurt',
    ),
    _translation(
      2705424,
      'Joghurt, griechischer Joghurt, fettfreie Milch, Naturjoghurt',
    ),
    _translation(2705427, 'Joghurt, fettarme Milch, Obst'),
    _translation(2705428, 'Joghurt, fettfreie Milch, Obst'),
    _translation(
      2705431,
      'Joghurt, griechischer Joghurt, fettarme Milch, Obst',
    ),
    _translation(
      2705432,
      'Joghurt, griechischer Joghurt, fettfreie Milch, Obst',
    ),
    _translation(
      2705435,
      'Joghurt, fettarme Milch, Geschmacksrichtungen außer Frucht',
    ),
    _translation(
      2705436,
      'Joghurt, fettfreie Milch, andere Geschmacksrichtungen als Frucht',
    ),
    _translation(
      2705439,
      'Joghurt, griechischer Joghurt, fettarme Milch, Geschmacksrichtungen außer Frucht',
    ),
    _translation(
      2705440,
      'Joghurt, griechischer Joghurt, fettfreie Milch, Geschmacksrichtungen außer Frucht',
    ),
    _translation(
      2705473,
      'Heiße Schokolade / Kakao, zubereitet mit Vollmilch oder fettarmer Milch (2 %)',
    ),
    _translation(
      2705474,
      'Heiße Schokolade / Kakao, zubereitet mit fettarmer (1 %) oder fettfreier (Magermilch) Milch',
    ),
    _translation(
      2705475,
      'Heiße Schokolade / Kakao, zubereitet mit pflanzlicher Milch',
    ),
    _translation(
      2705478,
      'Schokoladenmilch, Nesquik, zubereitet mit pflanzlicher Milch',
    ),
    _translation(
      2705484,
      'Heiße Schokolade / Kakao, Trockenmischung, zubereitet mit Vollmilch oder fettarmer Milch (2 %)',
    ),
    _translation(
      2705485,
      'Heiße Schokolade / Kakao, Trockenmischung, zubereitet mit fettarmer (1 %) oder fettfreier (Magermilch) Milch',
    ),
    _translation(
      2705486,
      'Heiße Schokolade / Kakao, Trockenmischung, zubereitet mit pflanzlicher Milch',
    ),
    _translation(
      2705489,
      'Heiße Schokolade / Kakao, Trockenmischung, zuckerreduziert, zubereitet mit Vollmilch oder fettarmer Milch (2 %)',
    ),
    _translation(
      2705490,
      'Heiße Schokolade / Kakao, zuckerreduziert, mit pflanzlicher Milch zubereitet',
    ),
    _translation(
      2705491,
      'Heiße Schokolade / Kakao, zuckerreduziert, zubereitet mit Vollmilch oder fettarmer Milch (2 %)',
    ),
    _translation(
      2705492,
      'Heiße Schokolade / Kakao, Trockenmischung, zuckerreduziert, zubereitet mit fettarmer (1 %) oder fettfreier (Magermilch) Milch',
    ),
    _translation(
      2705493,
      'Heiße Schokolade / Kakao, zuckerreduziert, zubereitet mit fettarmer (1 %) oder fettfreier (Magermilch) Milch',
    ),
    _translation(
      2705494,
      'Heiße Schokolade / Kakao, Trockenmischung, zuckerreduziert, zur Zubereitung mit pflanzlicher Milch',
    ),
    _translation(2705501, 'Milch, gemälzt'),
    _translation(2705585, 'Milch, trocken, nicht rekonstituiert'),
    _translation(
      2705590,
      'Milch, gemälzt, Trockenmischung, nicht rekonstituiert',
    ),
    _translation(2707192, 'Eierauflauf mit Brot, Käse, Milch und Fleisch'),
    _translation(2708086, 'Milch-Müsli-Riegel'),
    _translation(2708159, 'Cracker, Milch'),
    _translation(
      2708383,
      'Haferflocken, normal oder Instant, mit Milch zubereitet, ohne Fettzusatz',
    ),
    _translation(
      2708384,
      'Haferflocken, normal oder Instant, mit Milch zubereitet, mit Fettzusatz',
    ),
    _translation(
      2708385,
      'Haferflocken, normal oder Instant, zubereitet mit pflanzlicher Milch, ohne Fettzusatz',
    ),
    _translation(
      2708386,
      'Haferflocken, normal oder Instant, zubereitet mit pflanzlicher Milch, mit Fettzusatz',
    ),
    _translation(
      2708389,
      'Haferflocken, Instant, natur, mit Milch zubereitet, ohne Fettzusatz',
    ),
    _translation(
      2708390,
      'Haferflocken, Instant, natur, mit Milch zubereitet, mit Fettzusatz',
    ),
    _translation(
      2708391,
      'Haferflocken, Instant, natur, mit pflanzlicher Milch zubereitet, ohne Fettzusatz',
    ),
    _translation(
      2708392,
      'Haferflocken, Instant, natur, mit pflanzlicher Milch zubereitet, mit Fett angereichert',
    ),
    _translation(2708416, 'Gekochter Reis mit Milch'),
    _translation(
      2709496,
      'Kartoffelpüree aus frischen Kartoffeln, mit Milch zubereitet',
    ),
    _translation(
      2709497,
      'Kartoffelpüree aus frischen Kartoffeln, mit Milch zubereitet, mit Käse',
    ),
    _translation(
      2709498,
      'Kartoffelpüree aus frischen Kartoffeln, mit Milch zubereitet, mit Soße',
    ),
    _translation(
      2709504,
      'Kartoffelpüree aus Trockenmischung, mit Milch zubereitet',
    ),
    _translation(
      2709505,
      'Kartoffelpüree aus Trockenmischung, mit Milch zubereitet, mit Käse',
    ),
    _translation(
      2709506,
      'Kartoffelpüree aus Trockenmischung, mit Milch zubereitet, mit Soße',
    ),
    _translation(2710388, 'Kaffee, Latte, mit pflanzlicher Milch'),
    _translation(
      2710391,
      'Kaffee, Latte, mit pflanzlicher Milch, aromatisiert',
    ),
    _translation(
      2710394,
      'Kaffee, Latte, entkoffeiniert, mit pflanzlicher Milch',
    ),
    _translation(
      2710397,
      'Kaffee, Latte, entkoffeiniert, mit pflanzlicher Milch, aromatisiert',
    ),
    _translation(2710400, 'Gefrorenes Kaffeegetränk mit pflanzlicher Milch'),
    _translation(
      2710403,
      'Gefrorenes Kaffeegetränk mit pflanzlicher Milch und Schlagsahne',
    ),
    _translation(
      2710406,
      'Gefrorenes Kaffeegetränk, entkoffeiniert, mit pflanzlicher Milch',
    ),
    _translation(
      2710409,
      'Gefrorenes Kaffeegetränk, entkoffeiniert, mit pflanzlicher Milch und Schlagsahne',
    ),
    _translation(2710412, 'Kaffee, Café Mocha, mit pflanzlicher Milch'),
    _translation(
      2710415,
      'Kaffee, Café Mocha, entkoffeiniert, mit pflanzlicher Milch',
    ),
    _translation(
      2710418,
      'Gefrorenes Mokka-Kaffeegetränk mit pflanzlicher Milch',
    ),
    _translation(
      2710421,
      'Gefrorenes Mokka-Kaffeegetränk mit pflanzlicher Milch und Schlagsahne',
    ),
    _translation(
      2710424,
      'Gefrorenes Mokka-Kaffeegetränk, entkoffeiniert, mit pflanzlicher Milch',
    ),
    _translation(
      2710427,
      'Gefrorenes Mokka-Kaffeegetränk, entkoffeiniert, mit pflanzlicher Milch und Schlagsahne',
    ),
    _translation(2710430, 'Eiskaffee, bereits mit Milch und Zucker versetzt'),
    _translation(2710433, 'Kaffee, Eiskaffee mit pflanzlicher Milch'),
    _translation(
      2710436,
      'Kaffee, Eiskaffee mit pflanzlicher Milch, aromatisiert',
    ),
    _translation(
      2710439,
      'Kaffee, Eiskaffee, entkoffeiniert, mit pflanzlicher Milch',
    ),
    _translation(
      2710442,
      'Kaffee, Eiskaffee, entkoffeiniert, mit pflanzlicher Milch, aromatisiert',
    ),
    _translation(
      2710445,
      'Kaffee, Café Mocha (eiskalt), mit pflanzlicher Milch',
    ),
    _translation(
      2710448,
      'Kaffee, Café Mocha (eiskalt), entkoffeiniert, mit pflanzlicher Milch',
    ),
    _translation(2710474, 'Kaffee, Cappuccino, mit pflanzlicher Milch'),
    _translation(
      2710477,
      'Kaffee, Cappuccino, entkoffeiniert, mit pflanzlicher Milch',
    ),
    _translation(2710506, 'Tee, heiß, mit Milch'),
    _translation(2710603, 'Horchata, mit Milch zubereitet'),
    _translation(
      167588,
      'Pudding, Banane, Trockenmischung, Instant, zubereitet mit 2 % Milch',
    ),
    _translation(
      167589,
      'Pudding, Banane, Fertigmischung, normal, zubereitet mit 2 %iger Milch',
    ),
    _translation(
      167697,
      'Milch, Buttermilch, Trinkmilch, fermentierte Milch, fettarme Milch',
    ),
    _translation(167730, 'Milch, Ersatzprodukt, nicht aus Soja'),
    _translation(
      167998,
      'Pudding, Schokolade, Trockenmischung, Instant, zubereitet mit 2 % Milch',
    ),
    _translation(
      168103,
      'Gefrorene Joghurts, Schokolade, fettfreie Milch, ohne Zucker gesüßt',
    ),
    _translation(
      168554,
      'Kartoffelpüree, aus Granulat zubereitet, ohne Milch, Vollmilch und Margarine',
    ),
    _translation(
      168780,
      'Pudding, Schokolade, Trockenmischung, normal, zubereitet mit 2 %iger Milch',
    ),
    _translation(
      168781,
      'Puddings, Kokoscreme, Trockenmischung, Instant, zubereitet mit 2 % Milch',
    ),
    _translation(
      168786,
      'Pudding, Zitrone, Trockenmischung, Instant, zubereitet mit 2 % Milch',
    ),
    _translation(
      168787,
      'Eierpudding, Trockenmischung, zubereitet mit 2 %iger Milch',
    ),
    _translation(
      168788,
      'Pudding, Vanille, Trockenmischung, Standard, zubereitet mit 2 %iger Milch',
    ),
    _translation(
      168789,
      'Rennin, Schokolade, Trockenmischung, zubereitet mit 2 % Milch',
    ),
    _translation(
      168790,
      'Rennin, Vanille, Trockenmischung, zubereitet mit 2 % Milch',
    ),
    _translation(
      169372,
      'Kartoffeln, püriert, getrocknet, aus Flocken hergestellt, ohne Zusatz von Milch, Vollmilch und Margarine',
    ),
  ];
}
