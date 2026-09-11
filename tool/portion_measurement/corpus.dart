// The generated text corpus: the 503a4518 generator, extended so that most
// English and German lines carry a household measure — slices, pieces,
// cups, spoons, glasses, bowls, handfuls, sizes, abbreviations — and a
// smaller share of the other seven locales do too. Every line generated
// from a measure template carries the key the decided prompt asks for, so
// the report can say "the line said *Scheibe*, the key was `slice`".

import 'dart:math';

/// A food as a user in [locale] writes it, beside the English name the
/// harness resolves it by when the line is not English. The search the
/// app makes for a German query goes through `search_food_translation`,
/// which this measurement does not call; the English equivalent lands on
/// the same food's portion table, which is what the key is matched against.
class Food {
  final String local;
  final String en;

  const Food(this.local, this.en);
}

/// How a food is portioned in practice, so a line pairs a measure with a
/// food that admits it: "3 slices of bread", not "2 slices of orange
/// juice". A model asked the second may reasonably refuse the key, and the
/// emission rate would then be measuring the corpus rather than the prompt.
enum Kind { counted, sliced, liquid, pourable, spoonable, nuts }

/// By English name, so the nine locale lists share one table.
const kindsOf = <String, Set<Kind>>{
  'porridge': {Kind.pourable}, 'oatmeal': {Kind.pourable}, 'oats': {Kind.pourable},
  'banana': {Kind.counted}, 'greek yogurt': {Kind.pourable}, 'yogurt': {Kind.pourable},
  'chicken breast': {Kind.counted, Kind.sliced}, 'white rice': {Kind.pourable},
  'rice': {Kind.pourable}, 'spaghetti': {Kind.pourable}, 'pasta': {Kind.pourable},
  'salmon': {Kind.counted, Kind.sliced}, 'avocado': {Kind.counted, Kind.sliced},
  'latte': {Kind.liquid}, 'apple': {Kind.counted, Kind.sliced}, 'almonds': {Kind.nuts},
  'egg': {Kind.counted}, 'bacon': {Kind.counted, Kind.sliced}, 'orange juice': {Kind.liquid},
  'pizza': {Kind.sliced}, 'caesar salad': {Kind.pourable}, 'salad': {Kind.pourable},
  'lentil soup': {Kind.pourable}, 'ham sandwich': {Kind.counted},
  'cottage cheese': {Kind.pourable, Kind.spoonable}, 'granola': {Kind.pourable, Kind.nuts},
  'milk': {Kind.liquid}, 'cheddar': {Kind.sliced}, 'cheese': {Kind.sliced},
  'gouda': {Kind.sliced}, 'parmesan': {Kind.sliced, Kind.spoonable},
  'olive oil': {Kind.spoonable}, 'broccoli': {Kind.pourable, Kind.counted},
  'sweet potato': {Kind.counted}, 'sirloin steak': {Kind.counted, Kind.sliced},
  'steak': {Kind.counted, Kind.sliced}, 'beef steak': {Kind.counted, Kind.sliced},
  'tuna': {Kind.pourable, Kind.spoonable}, 'peanut butter': {Kind.spoonable},
  'whole wheat bread': {Kind.sliced}, 'bread': {Kind.sliced}, 'white bread': {Kind.sliced},
  'toast': {Kind.sliced}, 'coffee': {Kind.liquid}, 'green tea': {Kind.liquid},
  'dark chocolate': {Kind.sliced, Kind.counted}, 'hummus': {Kind.spoonable, Kind.pourable},
  'scrambled eggs': {Kind.pourable}, 'butter': {Kind.spoonable}, 'sugar': {Kind.spoonable},
  'honey': {Kind.spoonable}, 'watermelon': {Kind.sliced, Kind.counted},
  'cake': {Kind.sliced, Kind.counted}, 'borscht': {Kind.pourable}, 'dumplings': {Kind.counted},
  'pierogi': {Kind.counted}, 'lasagna': {Kind.sliced, Kind.counted}, 'risotto': {Kind.pourable},
};

/// Which kinds each key sits on.
const kindsForKey = <String, Set<Kind>>{
  'slice': {Kind.sliced},
  'piece': {Kind.counted, Kind.sliced},
  'cup': {Kind.pourable, Kind.liquid, Kind.nuts},
  'tablespoon': {Kind.spoonable},
  'teaspoon': {Kind.spoonable},
  'glass': {Kind.liquid},
  'bowl': {Kind.pourable},
  'handful': {Kind.nuts},
  'small': {Kind.counted, Kind.sliced},
  'medium': {Kind.counted, Kind.sliced},
  'large': {Kind.counted, Kind.sliced},
};

/// A household measure as written in one locale, with its inflections and
/// the English key the prompt asks for.
class Measure {
  final String singular;
  final String plural;
  final String key;

  /// True for `tbsp`, `tsp`, `EL`, `TL` — the forms the table has no rows
  /// for, which the prompt tells the model to write out.
  final bool abbreviation;

  /// True for small/medium/large, which read as an adjective, not a
  /// container: "2 large eggs" rather than "2 slices of bread".
  final bool size;

  const Measure(
    this.singular,
    this.plural,
    this.key, {
    this.abbreviation = false,
    this.size = false,
  });
}

const foods = <String, List<Food>>{
  'en': [
    Food('porridge', 'porridge'), Food('banana', 'banana'),
    Food('greek yogurt', 'greek yogurt'), Food('chicken breast', 'chicken breast'),
    Food('white rice', 'white rice'), Food('spaghetti', 'spaghetti'),
    Food('salmon', 'salmon'), Food('avocado', 'avocado'), Food('latte', 'latte'),
    Food('apple', 'apple'), Food('almonds', 'almonds'), Food('eggs', 'egg'),
    Food('bacon', 'bacon'), Food('orange juice', 'orange juice'),
    Food('pizza', 'pizza'), Food('caesar salad', 'caesar salad'),
    Food('lentil soup', 'lentil soup'), Food('ham sandwich', 'ham sandwich'),
    Food('cottage cheese', 'cottage cheese'), Food('granola', 'granola'),
    Food('milk', 'milk'), Food('cheddar', 'cheddar'), Food('olive oil', 'olive oil'),
    Food('broccoli', 'broccoli'), Food('sweet potato', 'sweet potato'),
    Food('sirloin steak', 'sirloin steak'), Food('tuna', 'tuna'),
    Food('peanut butter', 'peanut butter'), Food('wholemeal bread', 'whole wheat bread'),
    Food('white bread', 'white bread'), Food('black coffee', 'coffee'),
    Food('green tea', 'green tea'), Food('dark chocolate', 'dark chocolate'),
    Food('hummus', 'hummus'), Food('scrambled eggs', 'scrambled eggs'),
    Food('butter', 'butter'), Food('sugar', 'sugar'), Food('honey', 'honey'),
    Food('oatmeal', 'oatmeal'), Food('pasta', 'pasta'), Food('cheese', 'cheese'),
    Food('watermelon', 'watermelon'), Food('cake', 'cake'), Food('toast', 'toast'),
  ],
  'de': [
    Food('Haferflocken', 'oats'), Food('Banane', 'banana'),
    Food('griechischer Joghurt', 'greek yogurt'), Food('Hähnchenbrust', 'chicken breast'),
    Food('Reis', 'rice'), Food('Spaghetti', 'spaghetti'), Food('Lachs', 'salmon'),
    Food('Avocado', 'avocado'), Food('Milchkaffee', 'latte'), Food('Apfel', 'apple'),
    Food('Mandeln', 'almonds'), Food('Eier', 'egg'), Food('Speck', 'bacon'),
    Food('Orangensaft', 'orange juice'), Food('Pizza', 'pizza'),
    Food('Vollkornbrot', 'whole wheat bread'), Food('Brot', 'bread'),
    Food('Quark', 'cottage cheese'), Food('Müsli', 'granola'), Food('Milch', 'milk'),
    Food('Gouda', 'gouda'), Food('Olivenöl', 'olive oil'), Food('Brokkoli', 'broccoli'),
    Food('Süßkartoffel', 'sweet potato'), Food('Rindersteak', 'beef steak'),
    Food('Thunfisch', 'tuna'), Food('Erdnussbutter', 'peanut butter'),
    Food('Kaffee', 'coffee'), Food('grüner Tee', 'green tea'),
    Food('Zartbitterschokolade', 'dark chocolate'), Food('Rührei', 'scrambled eggs'),
    Food('Butter', 'butter'), Food('Zucker', 'sugar'), Food('Honig', 'honey'),
    Food('Käse', 'cheese'), Food('Nudeln', 'pasta'), Food('Wassermelone', 'watermelon'),
    Food('Kuchen', 'cake'), Food('Toast', 'toast'), Food('Salat', 'salad'),
  ],
  'zh': [
    Food('燕麦粥', 'oatmeal'), Food('香蕉', 'banana'), Food('鸡胸肉', 'chicken breast'),
    Food('白米饭', 'white rice'), Food('意大利面', 'spaghetti'), Food('三文鱼', 'salmon'),
    Food('牛油果', 'avocado'), Food('苹果', 'apple'), Food('杏仁', 'almonds'),
    Food('鸡蛋', 'egg'), Food('培根', 'bacon'), Food('橙汁', 'orange juice'),
    Food('披萨', 'pizza'), Food('牛奶', 'milk'), Food('橄榄油', 'olive oil'),
    Food('西兰花', 'broccoli'), Food('红薯', 'sweet potato'), Food('牛排', 'steak'),
    Food('花生酱', 'peanut butter'), Food('全麦面包', 'whole wheat bread'),
    Food('面包', 'bread'), Food('黑咖啡', 'coffee'), Food('绿茶', 'green tea'),
    Food('黑巧克力', 'dark chocolate'), Food('饺子', 'dumplings'), Food('蜂蜜', 'honey'),
    Food('糖', 'sugar'), Food('蛋糕', 'cake'), Food('西瓜', 'watermelon'),
  ],
  'uk': [
    Food('вівсянка', 'oatmeal'), Food('банан', 'banana'), Food('куряче філе', 'chicken breast'),
    Food('рис', 'rice'), Food('спагеті', 'spaghetti'), Food('лосось', 'salmon'),
    Food('авокадо', 'avocado'), Food('яблуко', 'apple'), Food('мигдаль', 'almonds'),
    Food('яйця', 'egg'), Food('бекон', 'bacon'), Food('апельсиновий сік', 'orange juice'),
    Food('піца', 'pizza'), Food('борщ', 'borscht'), Food('сир', 'cheese'),
    Food('молоко', 'milk'), Food('оливкова олія', 'olive oil'), Food('броколі', 'broccoli'),
    Food('стейк', 'steak'), Food('тунець', 'tuna'), Food('арахісова паста', 'peanut butter'),
    Food('хліб', 'bread'), Food('чорна кава', 'coffee'), Food('зелений чай', 'green tea'),
    Food('мед', 'honey'), Food('цукор', 'sugar'), Food('торт', 'cake'),
  ],
  'pl': [
    Food('owsianka', 'oatmeal'), Food('banan', 'banana'), Food('pierś z kurczaka', 'chicken breast'),
    Food('ryż', 'rice'), Food('spaghetti', 'spaghetti'), Food('łosoś', 'salmon'),
    Food('awokado', 'avocado'), Food('jabłko', 'apple'), Food('migdały', 'almonds'),
    Food('jajka', 'egg'), Food('boczek', 'bacon'), Food('sok pomarańczowy', 'orange juice'),
    Food('pizza', 'pizza'), Food('pierogi', 'pierogi'), Food('twaróg', 'cottage cheese'),
    Food('mleko', 'milk'), Food('ser żółty', 'cheese'), Food('oliwa z oliwek', 'olive oil'),
    Food('brokuły', 'broccoli'), Food('stek', 'steak'), Food('tuńczyk', 'tuna'),
    Food('masło orzechowe', 'peanut butter'), Food('chleb', 'bread'),
    Food('czarna kawa', 'coffee'), Food('zielona herbata', 'green tea'),
    Food('miód', 'honey'), Food('cukier', 'sugar'), Food('ciasto', 'cake'),
  ],
  'tr': [
    Food('yulaf lapası', 'oatmeal'), Food('muz', 'banana'), Food('yoğurt', 'yogurt'),
    Food('tavuk göğsü', 'chicken breast'), Food('pilav', 'rice'), Food('makarna', 'pasta'),
    Food('somon', 'salmon'), Food('avokado', 'avocado'), Food('elma', 'apple'),
    Food('badem', 'almonds'), Food('yumurta', 'egg'), Food('portakal suyu', 'orange juice'),
    Food('pizza', 'pizza'), Food('mercimek çorbası', 'lentil soup'), Food('süt', 'milk'),
    Food('kaşar peyniri', 'cheese'), Food('zeytinyağı', 'olive oil'), Food('brokoli', 'broccoli'),
    Food('biftek', 'steak'), Food('ton balığı', 'tuna'), Food('fıstık ezmesi', 'peanut butter'),
    Food('ekmek', 'bread'), Food('sade kahve', 'coffee'), Food('yeşil çay', 'green tea'),
    Food('bal', 'honey'), Food('şeker', 'sugar'), Food('kek', 'cake'),
  ],
  'cs': [
    Food('ovesná kaše', 'oatmeal'), Food('banán', 'banana'), Food('řecký jogurt', 'greek yogurt'),
    Food('kuřecí prsa', 'chicken breast'), Food('rýže', 'rice'), Food('špagety', 'spaghetti'),
    Food('losos', 'salmon'), Food('avokádo', 'avocado'), Food('jablko', 'apple'),
    Food('mandle', 'almonds'), Food('vejce', 'egg'), Food('slanina', 'bacon'),
    Food('pomerančový džus', 'orange juice'), Food('pizza', 'pizza'), Food('mléko', 'milk'),
    Food('eidam', 'cheese'), Food('olivový olej', 'olive oil'), Food('brokolice', 'broccoli'),
    Food('steak', 'steak'), Food('tuňák', 'tuna'), Food('arašídové máslo', 'peanut butter'),
    Food('chléb', 'bread'), Food('černá káva', 'coffee'), Food('zelený čaj', 'green tea'),
    Food('med', 'honey'), Food('cukr', 'sugar'), Food('dort', 'cake'),
  ],
  'sk': [
    Food('ovsená kaša', 'oatmeal'), Food('banán', 'banana'), Food('grécky jogurt', 'greek yogurt'),
    Food('kuracie prsia', 'chicken breast'), Food('ryža', 'rice'), Food('špagety', 'spaghetti'),
    Food('losos', 'salmon'), Food('avokádo', 'avocado'), Food('jablko', 'apple'),
    Food('mandle', 'almonds'), Food('vajcia', 'egg'), Food('slanina', 'bacon'),
    Food('pomarančový džús', 'orange juice'), Food('pizza', 'pizza'), Food('mlieko', 'milk'),
    Food('eidam', 'cheese'), Food('olivový olej', 'olive oil'), Food('brokolica', 'broccoli'),
    Food('steak', 'steak'), Food('tuniak', 'tuna'), Food('arašidové maslo', 'peanut butter'),
    Food('chlieb', 'bread'), Food('čierna káva', 'coffee'), Food('zelený čaj', 'green tea'),
    Food('med', 'honey'), Food('cukor', 'sugar'), Food('torta', 'cake'),
  ],
  'it': [
    Food('porridge', 'porridge'), Food('banana', 'banana'), Food('yogurt greco', 'greek yogurt'),
    Food('petto di pollo', 'chicken breast'), Food('riso', 'rice'), Food('spaghetti', 'spaghetti'),
    Food('salmone', 'salmon'), Food('avocado', 'avocado'), Food('mela', 'apple'),
    Food('mandorle', 'almonds'), Food('uova', 'egg'), Food('pancetta', 'bacon'),
    Food("succo d'arancia", 'orange juice'), Food('pizza', 'pizza'), Food('latte', 'milk'),
    Food('parmigiano', 'parmesan'), Food("olio d'oliva", 'olive oil'), Food('broccoli', 'broccoli'),
    Food('bistecca', 'steak'), Food('tonno', 'tuna'), Food('burro di arachidi', 'peanut butter'),
    Food('pane', 'bread'), Food('caffè', 'coffee'), Food('tè verde', 'green tea'),
    Food('miele', 'honey'), Food('zucchero', 'sugar'), Food('torta', 'cake'),
    Food('risotto', 'risotto'), Food('lasagne', 'lasagna'),
  ],
};

/// The measures, per locale. The English list carries the abbreviations the
/// prompt tells the model to write out; German carries `EL`/`TL`.
const measures = <String, List<Measure>>{
  'en': [
    Measure('slice', 'slices', 'slice'),
    Measure('piece', 'pieces', 'piece'),
    Measure('cup', 'cups', 'cup'),
    Measure('tablespoon', 'tablespoons', 'tablespoon'),
    Measure('teaspoon', 'teaspoons', 'teaspoon'),
    Measure('tbsp', 'tbsp', 'tablespoon', abbreviation: true),
    Measure('tsp', 'tsp', 'teaspoon', abbreviation: true),
    Measure('glass', 'glasses', 'glass'),
    Measure('bowl', 'bowls', 'bowl'),
    Measure('handful', 'handfuls', 'handful'),
    Measure('small', 'small', 'small', size: true),
    Measure('medium', 'medium', 'medium', size: true),
    Measure('large', 'large', 'large', size: true),
  ],
  'de': [
    Measure('Scheibe', 'Scheiben', 'slice'),
    Measure('Stück', 'Stück', 'piece'),
    Measure('Tasse', 'Tassen', 'cup'),
    Measure('Esslöffel', 'Esslöffel', 'tablespoon'),
    Measure('Teelöffel', 'Teelöffel', 'teaspoon'),
    Measure('EL', 'EL', 'tablespoon', abbreviation: true),
    Measure('TL', 'TL', 'teaspoon', abbreviation: true),
    Measure('Glas', 'Gläser', 'glass'),
    Measure('Schüssel', 'Schüsseln', 'bowl'),
    Measure('Handvoll', 'Handvoll', 'handful'),
    Measure('kleine', 'kleine', 'small', size: true),
    Measure('mittlere', 'mittlere', 'medium', size: true),
    Measure('große', 'große', 'large', size: true),
  ],
  'cs': [
    Measure('plátek', 'plátky', 'slice'),
    Measure('kus', 'kusy', 'piece'),
    Measure('hrnek', 'hrnky', 'cup'),
    Measure('lžíce', 'lžíce', 'tablespoon'),
    Measure('lžička', 'lžičky', 'teaspoon'),
    Measure('sklenice', 'sklenice', 'glass'),
    Measure('miska', 'misky', 'bowl'),
    Measure('hrst', 'hrsti', 'handful'),
    Measure('malý', 'malé', 'small', size: true),
    Measure('velký', 'velké', 'large', size: true),
  ],
  'it': [
    Measure('fetta', 'fette', 'slice'),
    Measure('pezzo', 'pezzi', 'piece'),
    Measure('tazza', 'tazze', 'cup'),
    Measure('cucchiaio', 'cucchiai', 'tablespoon'),
    Measure('cucchiaino', 'cucchiaini', 'teaspoon'),
    Measure('bicchiere', 'bicchieri', 'glass'),
    Measure('ciotola', 'ciotole', 'bowl'),
    Measure('manciata', 'manciate', 'handful'),
    Measure('piccola', 'piccole', 'small', size: true),
    Measure('grande', 'grandi', 'large', size: true),
  ],
  'pl': [
    Measure('kromka', 'kromki', 'slice'),
    Measure('kawałek', 'kawałki', 'piece'),
    Measure('filiżanka', 'filiżanki', 'cup'),
    Measure('łyżka', 'łyżki', 'tablespoon'),
    Measure('łyżeczka', 'łyżeczki', 'teaspoon'),
    Measure('szklanka', 'szklanki', 'glass'),
    Measure('miska', 'miski', 'bowl'),
    Measure('garść', 'garście', 'handful'),
    Measure('małe', 'małe', 'small', size: true),
    Measure('duże', 'duże', 'large', size: true),
  ],
  'sk': [
    Measure('plátok', 'plátky', 'slice'),
    Measure('kus', 'kusy', 'piece'),
    Measure('šálka', 'šálky', 'cup'),
    Measure('lyžica', 'lyžice', 'tablespoon'),
    Measure('lyžička', 'lyžičky', 'teaspoon'),
    Measure('pohár', 'poháre', 'glass'),
    Measure('miska', 'misky', 'bowl'),
    Measure('hrsť', 'hrste', 'handful'),
    Measure('malé', 'malé', 'small', size: true),
    Measure('veľké', 'veľké', 'large', size: true),
  ],
  'tr': [
    Measure('dilim', 'dilim', 'slice'),
    Measure('parça', 'parça', 'piece'),
    Measure('fincan', 'fincan', 'cup'),
    Measure('yemek kaşığı', 'yemek kaşığı', 'tablespoon'),
    Measure('çay kaşığı', 'çay kaşığı', 'teaspoon'),
    Measure('bardak', 'bardak', 'glass'),
    Measure('kase', 'kase', 'bowl'),
    Measure('avuç', 'avuç', 'handful'),
    Measure('küçük', 'küçük', 'small', size: true),
    Measure('büyük', 'büyük', 'large', size: true),
  ],
  'uk': [
    Measure('скибка', 'скибки', 'slice'),
    Measure('шматок', 'шматки', 'piece'),
    Measure('чашка', 'чашки', 'cup'),
    Measure('столова ложка', 'столові ложки', 'tablespoon'),
    Measure('чайна ложка', 'чайні ложки', 'teaspoon'),
    Measure('склянка', 'склянки', 'glass'),
    Measure('миска', 'миски', 'bowl'),
    Measure('жменя', 'жмені', 'handful'),
    Measure('маленьке', 'маленькі', 'small', size: true),
    Measure('велике', 'великі', 'large', size: true),
  ],
  'zh': [
    Measure('片', '片', 'slice'),
    Measure('块', '块', 'piece'),
    Measure('杯', '杯', 'cup'),
    Measure('汤匙', '汤匙', 'tablespoon'),
    Measure('茶匙', '茶匙', 'teaspoon'),
    Measure('碗', '碗', 'bowl'),
    Measure('把', '把', 'handful'),
    Measure('小', '小', 'small', size: true),
    Measure('大', '大', 'large', size: true),
  ],
};

/// Measure templates. `{n}` is a count, `{m}` the measure inflected for it,
/// `{f}` the food. `{a}` is the article-plus-singular form ("a glass of",
/// "ein Glas"). Sizes use `{s}` templates: the adjective before the food.
const measureTemplates = <String, List<String>>{
  'en': [
    '{n} {m} of {f}', '{n} {m} {f}', 'a {m} of {f}', 'I had {n} {m} of {f}',
    '{n} {m} of {f} for breakfast', '{f}, {n} {m}',
  ],
  'de': [
    '{n} {m} {f}', 'ein {m} {f}', 'eine {m} {f}', '{f}, {n} {m}',
    'ich hatte {n} {m} {f}', '{n} {m} {f} zum Frühstück',
  ],
  'cs': ['{n} {m} {f}', '{f}, {n} {m}', 'k snídani {n} {m} {f}'],
  'it': ['{n} {m} di {f}', 'una {m} di {f}', '{f}, {n} {m}'],
  'pl': ['{n} {m} {f}', '{f}, {n} {m}', 'na śniadanie {n} {m} {f}'],
  'sk': ['{n} {m} {f}', '{f}, {n} {m}', 'na raňajky {n} {m} {f}'],
  'tr': ['{n} {m} {f}', '{f}, {n} {m}', 'kahvaltıda {n} {m} {f}'],
  'uk': ['{n} {m} {f}', '{f}, {n} {m}', 'на сніданок {n} {m} {f}'],
  'zh': ['{n}{m}{f}', '{f}{n}{m}', '早餐{n}{m}{f}'],
};

const sizeTemplates = <String, List<String>>{
  'en': ['{n} {m} {f}', 'a {m} {f}', 'one {m} {f}', '{n} {m} {f} and coffee'],
  'de': ['{n} {m} {f}', 'ein {m}s {f}', 'eine {m} {f}', '{n} {m} {f} und Kaffee'],
  'cs': ['{n} {m} {f}', 'jedno {m} {f}'],
  'it': ['{n} {m} {f}', 'una {m} {f}'],
  'pl': ['{n} {m} {f}', 'jedno {m} {f}'],
  'sk': ['{n} {m} {f}', 'jedno {m} {f}'],
  'tr': ['{n} {m} {f}', 'bir {m} {f}'],
  'uk': ['{n} {m} {f}', 'одне {m} {f}'],
  'zh': ['{n}个{m}{f}', '一个{m}{f}'],
};

/// The old harness's plain templates, kept so the invariants still see the
/// shapes they were written against. `{q}` a number, `{u}` a unit, `{m}` a
/// meal name, `{s}` a vague size word inside the query.
const plainTemplates = <String, List<String>>{
  'en': [
    '{q}{u} {f}', '{q} {f}', '{f}', '{f} and {f2}', '{f}, {f2}, {f3}',
    '{q}{u} {f}, {q2} {f2}', 'I had {f} for {m}', 'about {q}{u} {f}',
    '{f} with {f2}', '{q}{u} {f} and {q2}{u2} {f2}', '{f} {q}{u}',
    'just {f}', '{m}: {f}, {f2}', '{q} {f} and some {f2}',
    '- {q}{u} {f}\n- {q2} {f2}', '{f} ({q}{u})', 'leftover {f}, {q}{u}',
  ],
  'de': [
    '{q}{u} {f}', '{q} {f}', '{f}', '{f} und {f2}', '{f}, {f2}, {f3}',
    '{q}{u} {f}, {q2} {f2}', 'zum {m} hatte ich {f}', 'ca. {q}{u} {f}',
    '{f} mit {f2}', '{q}{u} {f} und {q2}{u2} {f2}', '{f} {q}{u}',
    'nur {f}', '{m}: {f}, {f2}',
  ],
  'zh': [
    '{q}{u}{f}', '{q}个{f}', '{f}', '{f}和{f2}', '{f}、{f2}、{f3}',
    '{q}{u}{f}，{q2}个{f2}', '{m}吃了{f}', '大约{q}{u}{f}', '一份{f}',
    '{f}配{f2}', '{q}{u}{f}和{q2}{u2}{f2}',
  ],
  'uk': [
    '{q}{u} {f}', '{q} {f}', '{f}', '{f} і {f2}', '{f}, {f2}, {f3}',
    '{q}{u} {f}, {q2} {f2}', 'на {m} я їв {f}', 'приблизно {q}{u} {f}',
    '{f} з {f2}', '{q}{u} {f} і {q2}{u2} {f2}',
  ],
  'pl': [
    '{q}{u} {f}', '{q} {f}', '{f}', '{f} i {f2}', '{f}, {f2}, {f3}',
    '{q}{u} {f}, {q2} {f2}', 'na {m} zjadłem {f}', 'około {q}{u} {f}',
    '{f} z {f2}', '{q}{u} {f} i {q2}{u2} {f2}',
  ],
  'tr': [
    '{q}{u} {f}', '{q} {f}', '{f}', '{f} ve {f2}', '{f}, {f2}, {f3}',
    '{q}{u} {f}, {q2} {f2}', '{m} için {f} yedim', 'yaklaşık {q}{u} {f}',
    '{f} ile {f2}', '{q}{u} {f} ve {q2}{u2} {f2}',
  ],
  'cs': [
    '{q}{u} {f}', '{q} {f}', '{f}', '{f} a {f2}', '{f}, {f2}, {f3}',
    '{q}{u} {f}, {q2} {f2}', 'k {m} jsem měl {f}', 'asi {q}{u} {f}',
    '{f} s {f2}', '{q}{u} {f} a {q2}{u2} {f2}',
  ],
  'sk': [
    '{q}{u} {f}', '{q} {f}', '{f}', '{f} a {f2}', '{f}, {f2}, {f3}',
    '{q}{u} {f}, {q2} {f2}', 'na {m} som mal {f}', 'asi {q}{u} {f}',
    '{f} s {f2}', '{q}{u} {f} a {q2}{u2} {f2}',
  ],
  'it': [
    '{q}{u} {f}', '{q} {f}', '{f}', '{f} e {f2}', '{f}, {f2}, {f3}',
    '{q}{u} {f}, {q2} {f2}', 'a {m} ho mangiato {f}', 'circa {q}{u} {f}',
    '{f} con {f2}', '{q}{u} {f} e {q2}{u2} {f2}',
  ],
};

const meals = <String, List<String>>{
  'en': ['breakfast', 'lunch', 'dinner'],
  'de': ['Frühstück', 'Mittagessen', 'Abendessen'],
  'zh': ['早餐', '午餐', '晚餐'],
  'uk': ['сніданок', 'обід', 'вечерю'],
  'pl': ['śniadanie', 'obiad', 'kolację'],
  'tr': ['kahvaltı', 'öğle yemeği', 'akşam yemeği'],
  'cs': ['snídani', 'obědu', 'večeři'],
  'sk': ['raňajky', 'obed', 'večeru'],
  'it': ['colazione', 'pranzo', 'cena'],
};

const unitsByLocale = <String, List<String>>{
  'zh': ['g', '克', 'ml', '毫升', ''],
  'uk': ['g', 'г', 'ml', 'мл', ''],
  'de': ['g', 'ml', 'kg', 'l', ''],
};
const defaultUnits = ['g', 'ml', 'kg', 'l', 'oz', ''];

/// How the corpus is split. English and German carry the measurement; the
/// other seven are there to see whether the key stays English when the line
/// is not, and get a smaller share of measure lines each.
const localeWeights = <String, int>{
  'en': 30,
  'de': 25,
  'cs': 6,
  'it': 7,
  'pl': 7,
  'sk': 6,
  'tr': 6,
  'uk': 6,
  'zh': 7,
};
const measureShare = <String, double>{'en': 0.7, 'de': 0.7};
const defaultMeasureShare = 0.4;

/// One generated line and what the generator knows about it.
class Case {
  final String locale;
  final String input;

  /// Set when the line came from a measure or size template.
  final Expectation? expected;

  const Case(this.locale, this.input, {this.expected});

  Map<String, Object?> toJson() => {
    'locale': locale,
    'input': input,
    'expected': expected?.toJson(),
  };
}

/// What the decided prompt should produce for a measure line.
class Expectation {
  final Food food;
  final String measureWord;
  final String key;
  final double quantity;
  final bool abbreviation;
  final bool size;

  const Expectation({
    required this.food,
    required this.measureWord,
    required this.key,
    required this.quantity,
    required this.abbreviation,
    required this.size,
  });

  Map<String, Object?> toJson() => {
    'food': food.local,
    'foodEn': food.en,
    'measureWord': measureWord,
    'key': key,
    'quantity': quantity,
    'abbreviation': abbreviation,
    'size': size,
  };
}

List<Case> buildCorpus(int count, int seed) {
  final rng = Random(seed);
  final localeDraw = <String>[
    for (final e in localeWeights.entries)
      for (var i = 0; i < e.value; i++) e.key,
  ];
  final cases = <Case>[];
  final seen = <String>{};
  var guard = 0;

  while (cases.length < count && guard++ < count * 50) {
    final locale = localeDraw[rng.nextInt(localeDraw.length)];
    final share = measureShare[locale] ?? defaultMeasureShare;
    final c = rng.nextDouble() < share
        ? _measureCase(locale, rng)
        : _plainCase(locale, rng);
    if (seen.add('${c.locale}|${c.input}')) cases.add(c);
  }
  return cases;
}

Case _measureCase(String locale, Random rng) {
  final fs = foods[locale]!;
  final ms = measures[locale]!;
  final measure = ms[rng.nextInt(ms.length)];
  final admits = kindsForKey[measure.key] ?? const <Kind>{};
  final fitting = [
    for (final f in fs)
      if ((kindsOf[f.en] ?? const <Kind>{}).intersection(admits).isNotEmpty) f,
  ];
  final pool = fitting.isEmpty ? fs : fitting;
  final food = pool[rng.nextInt(pool.length)];
  final templates = measure.size ? sizeTemplates[locale]! : measureTemplates[locale]!;
  var template = templates[rng.nextInt(templates.length)];

  final counts = measure.size ? [1, 2, 3, 4] : [1, 2, 3, 4, 5, 6];
  // A template without `{n}` carries its own article ("a glass of", "ein
  // Glas"), which is a count of one.
  final n = template.contains('{n}') ? counts[rng.nextInt(counts.length)] : 1;
  final word = n == 1 ? measure.singular : measure.plural;
  // "a slice", "an apple": the English article follows the word.
  if (locale == 'en' && template.startsWith('a {m}')) {
    final vowel = RegExp('^[aeiou]', caseSensitive: false).hasMatch(word);
    if (vowel) template = 'an ${template.substring(2)}';
  }
  final input = template
      .replaceAll('{n}', '$n')
      .replaceAll('{m}', word)
      .replaceAll('{f}', food.local);
  return Case(
    locale,
    input,
    expected: Expectation(
      food: food,
      measureWord: word,
      key: measure.key,
      quantity: n.toDouble(),
      abbreviation: measure.abbreviation,
      size: measure.size,
    ),
  );
}

Case _plainCase(String locale, Random rng) {
  final fs = foods[locale]!;
  final t = plainTemplates[locale]!;
  final units = unitsByLocale[locale] ?? defaultUnits;
  String pickFood() => fs[rng.nextInt(fs.length)].local;
  String qty() {
    const choices = [
      '1', '2', '3', '100', '150', '200', '250', '30', '50', '500', '1,5',
      '0.5', '1.5',
    ];
    return choices[rng.nextInt(choices.length)];
  }

  final input = t[rng.nextInt(t.length)]
      .replaceAll('{f3}', pickFood())
      .replaceAll('{f2}', pickFood())
      .replaceAll('{f}', pickFood())
      .replaceAll('{q2}', qty())
      .replaceAll('{q}', qty())
      .replaceAll('{u2}', units[rng.nextInt(units.length)])
      .replaceAll('{u}', units[rng.nextInt(units.length)])
      .replaceAll('{m}', meals[locale]![rng.nextInt(meals[locale]!.length)]);
  return Case(locale, input);
}
