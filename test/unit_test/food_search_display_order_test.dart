import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';

import '../helpers/hive_test_setup.dart';

class _FakeProductsRepository implements ProductsRepository {
  final Map<String, List<MealEntity>> fdc = {};
  bool remoteDown = false;

  @override
  Future<List<MealEntity>> getSupabaseFoodsByString(
    String searchString, {
    bool forResolution = false,
  }) async {
    if (remoteDown) throw Exception('offline');
    return fdc[searchString] ?? const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _Intake implements GetIntakeUsecase {
  final List<IntakeEntity> recent = [];

  @override
  Future<List<IntakeEntity>> getRecentIntake() async => recent;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _NoCustomMeals implements CustomMealDataSource {
  @override
  List<MealDBO> getAllCustomMeals() => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _NoRecipes implements RecipeDataSource {
  @override
  List<RecipeDBO> getAllRecipes() => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _EverySourceEnabled implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      ConfigEntity(true, true, false, AppThemeEntity.system);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

/// A `search_food_translation` row for `de`: id, description, the source of
/// the food it names, and whether the translation is native.
typedef _Row = (int, String, String, bool);

/// The rows the 2.6.0 Pixel 6 run showed under *Lebensmittel* for `banane`
/// (#1473), plus the two plain bananas it did not show: the survey's
/// "Banana, raw" in its German translation and the BLS record. The plain
/// rows come last on purpose — the backend's own order for this query was
/// not captured, and last is the worst case for the client's cut.
const List<_Row> _bananeRows = [
  (
    1,
    'Puddings, Banane, Trockenmischung, normal, mit Ölzusatz',
    'fdc_sr_legacy',
    false,
  ),
  (
    2,
    'Joghurt, griechisch, 2 % Fett, Erdbeer-Banane, CHOBANI',
    'fdc_sr_legacy',
    false,
  ),
  (
    3,
    'Brot, Banane, nach Rezept zubereitet, mit Margarine',
    'fdc_sr_legacy',
    false,
  ),
  (
    4,
    'Babynahrung, Banane mit Beerenmischung, püriert',
    'fdc_sr_legacy',
    false,
  ),
  (5, 'Getränke, V8 SPLASH Smoothies, Erdbeere-Banane', 'fdc_sr_legacy', false),
  (6, 'Babynahrung, Obst, Banane und Erdbeere, Junior', 'fdc_sr_legacy', false),
  (7, 'Babynahrung, Obst, Apfelmus mit Banane, Junior', 'fdc_sr_legacy', false),
  (8, 'Getränke, V8 V-FUSION-Säfte, Erdbeere-Banane', 'fdc_sr_legacy', false),
  (9, 'Babynahrung, Saft, Orange, Apfel und Banane', 'fdc_sr_legacy', false),
  (10, 'Puddings, Banane, Trockenmischung, Instant', 'fdc_sr_legacy', false),
  (11, 'Babynahrung, Banane ohne Tapioka, püriert', 'fdc_sr_legacy', false),
  (12, 'Puddings, Banane, Fertigmischung, normal', 'fdc_sr_legacy', false),
  (13, 'Banane, roh', 'fdc_survey', false),
  (14, 'Banane roh', 'bls', true),
];

/// [rows] through the data source's cut and on into entities, as
/// `SpFoodDataSource._searchByTranslation` and `ProductsRepository` make
/// the Food tab's page of them.
List<MealEntity> _page(List<_Row> rows, String query) {
  final cut = rankAndTruncateTranslationRows([
    for (final row in rows)
      {
        SPConst.translationFoodId: row.$1,
        SPConst.translationDescription: row.$2,
        SPConst.translationSource: row.$4 ? 'native' : 'machine',
      },
  ], query);
  final byId = {for (final row in rows) row.$1: row};
  return [
    for (final translation in cut)
      () {
        final row = byId[translation[SPConst.translationFoodId] as int]!;
        return MealEntity.fromSpFood(
          SpFoodDTO(
            foodId: row.$1,
            source: row.$3,
            sourceCode: '${row.$1}',
            name: 'English ${row.$1}',
          )..localizedName = row.$2,
        );
      }(),
  ];
}

List<String?> _names(List<MealEntity> meals) => [
  for (final meal in meals) meal.name,
];

/// #1473 on the Food tab's real path: the data source's cut, the real
/// `SearchProductsUseCase` and a real Hive-backed search cache, with only
/// the network faked.
///
/// The cut was never where the plain banana lost: it ranks it first. The
/// list lost it after: `searchFDCFoodByString` writes the page to the
/// cache before `_buildResult` reads the cache back, and the list was
/// cache-first, most recently touched first. Every new row of the page
/// carries one timestamp and the box is past the 32 entries where
/// `List.sort` stops keeping ties in place, so the page came back in no
/// particular order — "Puddings, Banane, Trockenmischung, normal, mit
/// Ölzusatz" on top, as on the phone — and a row an earlier search had
/// cached sank below all of them.
void main() {
  late Box<MealDBO> cacheBox;
  late Box<int> timestampsBox;
  late RemoteSearchCacheDataSource cache;
  late _FakeProductsRepository repository;
  late _Intake intake;
  late SearchProductsUseCase useCase;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Hive.init('.');
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    cacheBox = await Hive.openBox<MealDBO>('food_order_cache_test_$stamp');
    timestampsBox = await Hive.openBox<int>('food_order_ts_test_$stamp');
    cache = RemoteSearchCacheDataSource(cacheBox, timestampsBox);
    repository = _FakeProductsRepository();
    intake = _Intake();
    useCase = SearchProductsUseCase(
      repository,
      intake,
      _NoCustomMeals(),
      cache,
      _NoRecipes(),
      _EverySourceEnabled(),
    );
  });

  tearDown(() async {
    await cacheBox.deleteFromDisk();
    await timestampsBox.deleteFromDisk();
  });

  Future<List<MealEntity>> search(String query) async =>
      (await useCase.searchFDCFoodByString(query)).meals;

  /// An earlier `apfel` search, as the Pixel run made before `banane`: a
  /// page of its own in the cache, one row of which — the baby juice —
  /// `banane` finds too.
  Future<void> searchApfelFirst() async {
    repository.fdc['apfel'] = _page([
      for (var i = 0; i < 30; i++)
        (100 + i, 'Apfel, Sorte $i', 'fdc_sr_legacy', false),
      _bananeRows[8],
    ], 'apfel');
    await search('apfel');
  }

  test('the cut ranks the plain bananas first', () {
    final page = _page(_bananeRows, 'banane');

    expect(_names(page).take(2), ['Banane, roh', 'Banane roh']);
    // Below them, every row scores alike — its title plus the "Banane" it
    // names — and the shorter description goes first.
    final rest = [for (final meal in page.skip(2)) meal.name!.length];
    expect(rest, [...rest]..sort());
  });

  test('the Food tab lists the page in the order the cut ranked it', () async {
    await searchApfelFirst();
    final page = _page(_bananeRows, 'banane');
    repository.fdc['banane'] = page;

    final listed = await search('banane');

    expect(_names(listed), _names(page));
    expect(listed.first.name, 'Banane, roh');
  });

  test('a search repeated lists the page in the same order', () async {
    await searchApfelFirst();
    final page = _page(_bananeRows, 'banane');
    repository.fdc['banane'] = page;

    await search('banane');
    final again = await search('banane');

    expect(_names(again), _names(page));
  });

  test(
    'a plain food an earlier search cached keeps its place in the page',
    () async {
      // "banane roh" cached both plain bananas a day before; "banane" then
      // brings twelve rows the cache has never seen.
      repository.fdc['banane roh'] = _page(_bananeRows.sublist(12), 'banane');
      await search('banane roh');
      final page = _page(_bananeRows, 'banane');
      repository.fdc['banane'] = page;

      final first = await search('banane');
      final second = await search('banane');

      expect(_names(first).take(2), ['Banane, roh', 'Banane roh']);
      expect(_names(second), _names(first));
    },
  );

  test('a record the user logged goes above the page', () async {
    final page = _page(_bananeRows, 'banane');
    repository.fdc['banane'] = page;
    final instant = page.firstWhere(
      (meal) => meal.name == 'Puddings, Banane, Trockenmischung, Instant',
    );
    intake.recent.add(
      IntakeEntity(
        id: 'i1',
        unit: 'g',
        amount: 100,
        type: IntakeTypeEntity.snack,
        meal: instant,
        dateTime: DateTime.utc(2026, 10, 25),
      ),
    );

    final listed = await search('banane');

    expect(_names(listed), [
      instant.name,
      for (final meal in page)
        if (meal.code != instant.code) meal.name,
    ]);
  });

  test(
    'offline, the cache lists what it holds in the order it was cached',
    () async {
      final page = _page(_bananeRows, 'banane');
      repository.fdc['banane'] = page;
      await searchApfelFirst();
      await search('banane');

      repository.remoteDown = true;
      final listed = await search('banane');

      expect(_names(listed), _names(page));
    },
  );
}
