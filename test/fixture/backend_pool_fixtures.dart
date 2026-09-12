import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';

/// Two candidate pools too large for the data source's twenty, copied from
/// the live backend on 2026-09-13 for #1170.
///
/// The English one is the whole FDC survey family under the short title
/// "Potato": all 106 `food` rows with `source = 'fdc_survey'` and
/// `short_title = 'Potato'`, as `id` and `description`, in the order
/// `search_food_summary` returns rows — records with a deliverable
/// portion first (`food_has_deliverable_portion(id)`), then by id — so
/// that a test hands `rankAndTruncateFoodsByName` the pool the app would
/// be handed. Beside each, the number of portions
/// `portions_by_food_ids(ids, 'en')` delivers for it, which is what
/// `MealEntity.portions` holds once `ProductsRepository` has decorated a
/// fresh page, and what the resolver's portions key counts. No row is
/// edited; "Potato, boiled, from fresh,  peel eaten, no added fat"
/// carries the backend's double space.
///
/// The German one is `search_food_translation('Milch', 'de', 100)` as it
/// answered: the 100 `food_translation` rows the app's localized search
/// ranks and cuts, as `food_id`, `description` and `source`, in the
/// function's order. 2705384's German description is "Milch, NFS", so the
/// survey's generic milk is titled "Milch" in German as it is "Milk" in
/// English.
///
/// The twenty rows the data source keeps out of each are the resolver's
/// whole world for the query, which is why the pools are real and whole:
/// the family is what the truncation has to keep the right member of.
class BackendPoolFixtures {
  static SpFoodDTO _survey(int id, String description) => SpFoodDTO(
    foodId: id,
    source: 'fdc_survey',
    sourceCode: '$id',
    name: description,
    shortTitle: 'Potato',
  );

  static const potatoNfs = 2709382;
  static const potatoFrenchFriesFastFood = 2709461;
  static const potatoCookedAsIngredient = 2710790;

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
