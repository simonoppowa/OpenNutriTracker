// Runs a large generated corpus of realistic meal lines against the live
// API, checking invariants that must hold for *any* input rather than
// per-case expectations.
//
// Three things it looks for that a hand-written probe list cannot:
//
//  1. Invariant violations at scale — a nutrition word in a query, a unit
//     outside the enum, a stranded digit, an implausible quantity.
//  2. Disagreement with the deterministic parser on inputs the parser
//     handles. The model should not be worse than the offline path.
//  3. Instability — the same input asked twice. A model that answers
//     `3 g`, `300 g` and `3 serving` across runs cannot be made safe by
//     prompt wording alone.
//
//   fvm dart run tool/live_interpreter_corpus.dart <key-file> [count]

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:opennutritracker/features/add_meal/data/anthropic_meal_text_interpreter.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_text_interpreter.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

/// Foods people actually log, per locale.
const foods = <String, List<String>>{
  'en': [
    'porridge', 'banana', 'greek yoghurt', 'chicken breast', 'white rice',
    'spaghetti', 'salmon fillet', 'avocado', 'latte', 'protein shake',
    'apple', 'almonds', 'eggs', 'bacon', 'orange juice', 'pizza',
    'caesar salad', 'burrito', 'sushi', 'lentil soup', 'ham sandwich',
    'cottage cheese', 'granola', 'semi skimmed milk', 'cheddar',
    'olive oil', 'broccoli', 'sweet potato', 'sirloin steak', 'tuna',
    'peanut butter', 'wholemeal bread', 'black coffee', 'green tea',
    'dark chocolate', 'hummus', 'falafel wrap', 'scrambled eggs',
  ],
  'de': [
    'Haferflocken', 'Banane', 'griechischer Joghurt', 'Hähnchenbrust',
    'Reis', 'Spaghetti', 'Lachsfilet', 'Avocado', 'Milchkaffee',
    'Proteinshake', 'Apfel', 'Mandeln', 'Eier', 'Speck', 'Orangensaft',
    'Pizza', 'Caesar Salat', 'Vollkornbrot', 'Quark', 'Müsli',
    'fettarme Milch', 'Gouda', 'Olivenöl', 'Brokkoli', 'Süßkartoffel',
    'Rindersteak', 'Thunfisch', 'Erdnussbutter', 'schwarzer Kaffee',
    'grüner Tee', 'Zartbitterschokolade', 'Rührei', 'Bratkartoffeln',
  ],
  'zh': [
    '燕麦粥', '香蕉', '希腊酸奶', '鸡胸肉', '白米饭', '意大利面',
    '三文鱼', '牛油果', '拿铁', '蛋白粉', '苹果', '杏仁', '鸡蛋',
    '培根', '橙汁', '披萨', '凯撒沙拉', '寿司', '扁豆汤', '三明治',
    '牛奶', '切达奶酪', '橄榄油', '西兰花', '红薯', '牛排', '金枪鱼',
    '花生酱', '全麦面包', '黑咖啡', '绿茶', '黑巧克力', '饺子', '包子',
  ],
  'uk': [
    'вівсянка', 'банан', 'грецький йогурт', 'куряче філе', 'рис',
    'спагеті', 'лосось', 'авокадо', 'лате', 'протеїновий коктейль',
    'яблуко', 'мигдаль', 'яйця', 'бекон', 'апельсиновий сік', 'піца',
    'салат Цезар', 'борщ', 'вареники', 'сир', 'молоко', 'оливкова олія',
    'броколі', 'батат', 'стейк', 'тунець', 'арахісова паста',
    'чорний хліб', 'чорна кава', 'зелений чай',
  ],
  'pl': [
    'owsianka', 'banan', 'jogurt grecki', 'pierś z kurczaka', 'ryż',
    'spaghetti', 'łosoś', 'awokado', 'latte', 'odżywka białkowa',
    'jabłko', 'migdały', 'jajka', 'boczek', 'sok pomarańczowy', 'pizza',
    'sałatka cezar', 'pierogi', 'twaróg', 'mleko', 'ser żółty',
    'oliwa z oliwek', 'brokuły', 'batat', 'stek', 'tuńczyk',
    'masło orzechowe', 'chleb razowy', 'czarna kawa', 'zielona herbata',
  ],
  'tr': [
    'yulaf lapası', 'muz', 'yoğurt', 'tavuk göğsü', 'pilav', 'makarna',
    'somon', 'avokado', 'latte', 'protein tozu', 'elma', 'badem',
    'yumurta', 'pastırma', 'portakal suyu', 'pizza', 'sezar salata',
    'mercimek çorbası', 'sandviç', 'süt', 'kaşar peyniri', 'zeytinyağı',
    'brokoli', 'tatlı patates', 'biftek', 'ton balığı', 'fıstık ezmesi',
    'tam buğday ekmeği', 'sade kahve', 'yeşil çay', 'menemen',
  ],
  'cs': [
    'ovesná kaše', 'banán', 'řecký jogurt', 'kuřecí prsa', 'rýže',
    'špagety', 'losos', 'avokádo', 'latte', 'proteinový nápoj',
    'jablko', 'mandle', 'vejce', 'slanina', 'pomerančový džus', 'pizza',
    'caesar salát', 'čočková polévka', 'sendvič', 'mléko', 'eidam',
    'olivový olej', 'brokolice', 'batáty', 'steak', 'tuňák',
    'arašídové máslo', 'celozrnný chléb', 'černá káva', 'zelený čaj',
  ],
  'sk': [
    'ovsená kaša', 'banán', 'grécky jogurt', 'kuracie prsia', 'ryža',
    'špagety', 'losos', 'avokádo', 'latte', 'proteínový nápoj',
    'jablko', 'mandle', 'vajcia', 'slanina', 'pomarančový džús', 'pizza',
    'cézar šalát', 'šošovicová polievka', 'sendvič', 'mlieko', 'eidam',
    'olivový olej', 'brokolica', 'batáty', 'steak', 'tuniak',
    'arašidové maslo', 'celozrnný chlieb', 'čierna káva', 'zelený čaj',
  ],
  'it': [
    'porridge', 'banana', 'yogurt greco', 'petto di pollo', 'riso',
    'spaghetti', 'salmone', 'avocado', 'caffellatte', 'proteine in polvere',
    'mela', 'mandorle', 'uova', 'pancetta', 'succo d\'arancia', 'pizza',
    'insalata cesare', 'zuppa di lenticchie', 'panino', 'latte',
    'parmigiano', 'olio d\'oliva', 'broccoli', 'patata dolce', 'bistecca',
    'tonno', 'burro di arachidi', 'pane integrale', 'caffè nero',
    'tè verde', 'risotto', 'lasagne',
  ],
};

/// How people actually write it. `{f}`, `{f2}`, `{f3}` are foods; `{q}` a
/// number; `{u}` a unit; `{m}` a meal name; `{s}` a vague size word.
const templates = <String, List<String>>{
  'en': [
    '{q}{u} {f}', '{q} {f}', '{f}', '{f} and {f2}', '{f}, {f2}, {f3}',
    '{q}{u} {f}, {q2} {f2}', 'I had {f} for {m}', 'about {q}{u} {f}',
    'a {s} {f}', '{f} with {f2}', '{q}{u} {f} and {q2}{u2} {f2}',
    '{f} {q}{u}', 'just {f}', '{m}: {f}, {f2}', '{q} {f} and some {f2}',
    '- {q}{u} {f}\n- {q2} {f2}', '{f} ({q}{u})', 'leftover {f}, {q}{u}',
  ],
  'de': [
    '{q}{u} {f}', '{q} {f}', '{f}', '{f} und {f2}', '{f}, {f2}, {f3}',
    '{q}{u} {f}, {q2} {f2}', 'zum {m} hatte ich {f}', 'ca. {q}{u} {f}',
    'ein {s} {f}', '{f} mit {f2}', '{q}{u} {f} und {q2}{u2} {f2}',
    '{f} {q}{u}', 'nur {f}', '{m}: {f}, {f2}',
  ],
  'zh': [
    '{q}{u}{f}', '{q}个{f}', '{f}', '{f}和{f2}', '{f}、{f2}、{f3}',
    '{q}{u}{f}，{q2}个{f2}', '{m}吃了{f}', '大约{q}{u}{f}',
    '一份{f}', '{f}配{f2}', '{q}{u}{f}和{q2}{u2}{f2}',
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

const sizes = <String, List<String>>{
  'en': ['small', 'large', 'big'],
  'de': ['kleines', 'großes', 'halbes'],
  'zh': ['小', '大'],
  'uk': ['маленьке', 'велике'],
  'pl': ['małe', 'duże'],
  'tr': ['küçük', 'büyük'],
  'cs': ['malé', 'velké'],
  'sk': ['malé', 'veľké'],
  'it': ['piccola', 'grande'],
};

/// Units as people type them, including ones the app cannot convert.
const unitsByLocale = <String, List<String>>{
  'zh': ['g', '克', 'ml', '毫升', ''],
  'uk': ['g', 'г', 'ml', 'мл', ''],
  'de': ['g', 'ml', 'kg', 'l', ''],
};
const defaultUnits = ['g', 'ml', 'kg', 'l', 'oz', ''];

const _allowedUnits = {'g', 'ml', 'g/ml', 'oz', 'fl.oz', 'serving'};

class Case {
  final String locale;
  final String input;
  const Case(this.locale, this.input);
}

List<Case> buildCorpus(int count, int seed) {
  final rng = Random(seed);
  final locales = foods.keys.toList();
  final cases = <Case>[];
  final seen = <String>{};

  while (cases.length < count) {
    final locale = locales[rng.nextInt(locales.length)];
    final f = foods[locale]!;
    final t = templates[locale]!;
    final units = unitsByLocale[locale] ?? defaultUnits;

    String pickFood() => f[rng.nextInt(f.length)];
    String qty() {
      final choices = ['1', '2', '3', '100', '150', '200', '250', '30',
        '50', '500', '1,5', '0.5', '1.5'];
      return choices[rng.nextInt(choices.length)];
    }

    var input = t[rng.nextInt(t.length)];
    input = input
        .replaceAll('{f3}', pickFood())
        .replaceAll('{f2}', pickFood())
        .replaceAll('{f}', pickFood())
        .replaceAll('{q2}', qty())
        .replaceAll('{q}', qty())
        .replaceAll('{u2}', units[rng.nextInt(units.length)])
        .replaceAll('{u}', units[rng.nextInt(units.length)])
        .replaceAll('{m}', meals[locale]![rng.nextInt(meals[locale]!.length)])
        .replaceAll('{s}', sizes[locale]![rng.nextInt(sizes[locale]!.length)]);

    if (seen.add('$locale|$input')) cases.add(Case(locale, input));
  }
  return cases;
}

/// Must hold for any input at all. Returns the violations found.
List<String> invariants(String input, MealTextParseResult r) {
  final bad = <String>[];
  // Only words that never appear in a food name. An earlier version
  // included `protein`, `fat` and `carb` and flagged "protein shake",
  // "protein tozu" and "low fat yoghurt" — real foods the user typed,
  // reported as leaked nutrition values. A check that cries wolf on
  // ordinary input is worse than no check.
  final nutrition = RegExp(
    r'\b(kcal|calorie|calories|kilojoule|kj)\b',
    caseSensitive: false,
  );

  for (final item in r.items) {
    if (item.query.trim().isEmpty) bad.add('empty query');
    if (nutrition.hasMatch(item.query)) {
      bad.add('nutrition word in query "${item.query}"');
    }
    if (RegExp(r'\d').hasMatch(item.query) &&
        RegExp(r'^\s*\d').hasMatch(item.query)) {
      bad.add('query starts with a digit: "${item.query}"');
    }
    final u = item.unit;
    if (u != null && !_allowedUnits.contains(u)) {
      bad.add('unit "$u" outside the app set');
    }
    final q = item.quantity;
    if (q != null && (!q.isFinite || q <= 0 || q > 10000)) {
      bad.add('quantity $q out of range after validation');
    }
    if (u != null && q == null) bad.add('unit with no quantity');
  }
  // A single short line should not explode into many items.
  final commas = ','.allMatches(input).length + '，'.allMatches(input).length;
  if (r.items.length > commas + 4) {
    bad.add('${r.items.length} items from a line with $commas separators');
  }
  return bad;
}

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('usage: dart run tool/live_interpreter_corpus.dart '
        '<key-file> [count]');
    exit(64);
  }
  final keyFile = File(args.first);
  if (!keyFile.existsSync()) {
    stderr.writeln('key file not found');
    exit(66);
  }
  final apiKey = keyFile.readAsStringSync().trim();
  if (apiKey.isEmpty) {
    stderr.writeln('key file is empty');
    exit(65);
  }
  final count = args.length > 1 ? int.parse(args[1]) : 1000;

  final corpus = buildCorpus(count, 20260814);
  final client = http.Client();
  final interpreter = AnthropicMealTextInterpreter(client, () => apiKey);

  final violations = <String>[];
  final disagreements = <String>[];
  final latencies = <int>[];
  final unitCounts = <String, int>{};
  var callFailures = 0;
  var emptyResults = 0;
  var done = 0;

  Future<void> runOne(Case c) async {
    final started = DateTime.now();
    MealTextParseResult r;
    try {
      r = await _withRetry(
        () => interpreter.interpret(c.input, localeCode: c.locale),
      );
    } on MealTextInterpreterException catch (e) {
      callFailures++;
      violations.add('- CALL FAILED (${e.statusCode ?? '-'}) `${c.input}`');
      return;
    } finally {
      latencies.add(DateTime.now().difference(started).inMilliseconds);
      if (++done % 50 == 0) stdout.writeln('  $done/$count');
    }

    if (r.items.isEmpty) emptyResults++;
    for (final i in r.items) {
      unitCounts[i.unit ?? '(none)'] =
          (unitCounts[i.unit ?? '(none)'] ?? 0) + 1;
    }

    final bad = invariants(c.input, r);
    if (bad.isNotEmpty) {
      violations.add('- `${c.input.replaceAll('\n', ' / ')}` _${c.locale}_ — '
          '${bad.join('; ')}');
    }

    // Differential: where the offline parser is confident, the model should
    // not contradict it.
    final offline = parseMealText(c.input);
    if (offline.items.length == r.items.length && offline.items.isNotEmpty) {
      for (var i = 0; i < offline.items.length; i++) {
        final a = offline.items[i];
        final b = r.items[i];
        if (a.quantity != null &&
            b.quantity != null &&
            a.unit != null &&
            b.unit != null &&
            a.unit == b.unit &&
            (a.quantity! - b.quantity!).abs() > 0.001) {
          disagreements.add('- `${c.input}` item $i: parser '
              '${a.quantity}${a.unit}, model ${b.quantity}${b.unit}');
        }
      }
    }
  }

  // Bounded concurrency so a burst does not trip rate limits.
  const lanes = 8;
  for (var i = 0; i < corpus.length; i += lanes) {
    final slice = corpus.skip(i).take(lanes);
    await Future.wait(slice.map(runOne));
  }

  // Stability: ask a sample twice and see whether the answer moves.
  final rng = Random(7);
  final sample = [
    for (var i = 0; i < 40; i++) corpus[rng.nextInt(corpus.length)],
  ];
  var unstable = 0;
  final unstableExamples = <String>[];
  for (final c in sample) {
    try {
      final a = await interpreter.interpret(c.input, localeCode: c.locale);
      final b = await interpreter.interpret(c.input, localeCode: c.locale);
      String sig(MealTextParseResult r) => r.items
          .map((i) => '${i.query}|${i.quantity}|${i.unit}')
          .join(' ~ ');
      if (sig(a) != sig(b)) {
        unstable++;
        unstableExamples.add('- `${c.input}`\n  - ${sig(a)}\n  - ${sig(b)}');
      }
    } on MealTextInterpreterException {
      // counted elsewhere
    }
  }

  latencies.sort();
  final report = StringBuffer()
    ..writeln('# Live interpreter corpus')
    ..writeln()
    ..writeln('${corpus.length} generated meal lines across '
        '${foods.length} locales, model '
        '`${AnthropicMealTextInterpreter.defaultModel}`, '
        '${DateTime.now().toUtc().toIso8601String()}.')
    ..writeln()
    ..writeln('Checked against invariants that must hold for *any* input, '
        'not per-case expectations, plus a differential against '
        '`parseMealText` and a repeat-stability sample.')
    ..writeln()
    ..writeln('## Summary')
    ..writeln()
    ..writeln('| | |')
    ..writeln('| :-- | --: |')
    ..writeln('| Lines | ${corpus.length} |')
    ..writeln('| Invariant violations | **${violations.length}** |')
    ..writeln('| Call failures | $callFailures |')
    ..writeln('| Empty results | $emptyResults |')
    ..writeln('| Parser disagreements | ${disagreements.length} |')
    ..writeln('| Unstable on repeat (of ${sample.length}) | **$unstable** |')
    ..writeln('| Latency median | ${latencies[latencies.length ~/ 2]}ms |')
    ..writeln('| Latency p95 | '
        '${latencies[(latencies.length * 0.95).floor()]}ms |')
    ..writeln('| Latency max | ${latencies.last}ms |')
    ..writeln()
    ..writeln('### Units returned')
    ..writeln();
  final sortedUnits = unitCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final e in sortedUnits) {
    report.writeln('- `${e.key}` × ${e.value}');
  }

  void section(String title, List<String> lines, {int limit = 60}) {
    report..writeln()..writeln('## $title (${lines.length})')..writeln();
    if (lines.isEmpty) {
      report.writeln('_none_');
      return;
    }
    report.writeAll(lines.take(limit), '\n');
    if (lines.length > limit) {
      report.writeln('\n\n_… ${lines.length - limit} more_');
    }
    report.writeln();
  }

  section('Invariant violations', violations);
  section('Disagreements with the deterministic parser', disagreements);
  section('Unstable on repeat', unstableExamples);

  client.close();
  File('docs/live-interpreter-corpus.md').writeAsStringSync(report.toString());
  stdout.writeln('\nviolations ${violations.length} | failures $callFailures '
      '| disagreements ${disagreements.length} | unstable $unstable/'
      '${sample.length}');
  stdout.writeln(jsonEncode({
    'violations': violations.length,
    'callFailures': callFailures,
    'disagreements': disagreements.length,
    'unstable': unstable,
  }));
}

Future<MealTextParseResult> _withRetry(
  Future<MealTextParseResult> Function() call,
) async {
  for (var attempt = 0; ; attempt++) {
    try {
      return await call();
    } on MealTextInterpreterException catch (e) {
      if (!e.isTransient || attempt >= 3) rethrow;
      await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
    }
  }
}
