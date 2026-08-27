# Is the USDA FoodData Central path reachable at runtime?

Research for [#868](https://github.com/simonoppowa/OpenNutriTracker/issues/868), on map [#867](https://github.com/simonoppowa/OpenNutriTracker/issues/867). Written 2026-08-27. Baseline: tag `v2.0.2` (commit `9ab14fe3`), which is what `main` is at. All line numbers below are `v2.0.2` unless stated otherwise.

## Short answer

**Not reachable. `api.nal.usda.gov` receives nothing from the released app under any condition — no setting, no flag, no fallback, no hidden screen.** The direct FDC client is instantiated on every launch and injected into `ProductsRepository`, but the one repository method that would use it, `getFDCFoodsByString`, has **zero callers anywhere in the tree** — not in `lib/`, not in tests, not in tooling. The trail breaks at exactly one line: the use case named `searchFDCFoodByString` calls `getSupabaseFoodsByString`, not `getFDCFoodsByString`. The "FDC" naming throughout the search stack is a label for *which corpus the results came from*, not for *which host was contacted*.

The README's claim that a search "reaches that backend and stops there" is **accurate as written**. USDA FoodData Central is **not** a live recipient and does not belong on the recipients list.

## What the direct client would send, if it were reached

Establishing the payload first, because it is what would have to be disclosed if any hop connected.

`FDCDataSource.fetchSearchWordResults` ([`fdc_data_source.dart:15-36`](../lib/features/add_meal/data/data_sources/fdc_data_source.dart)) builds its URL via `FDCConst.getFDCWordSearchUrl(searchString, Env.fdcApiKey)` (`fdc_data_source.dart:17-20`) and issues a plain `http.get` with a 10-second timeout (`fdc_data_source.dart:23`).

`FDCConst.getFDCWordSearchUrl` ([`fdc_const.dart:168-178`](../lib/features/add_meal/data/dto/fdc/fdc_const.dart)) returns `Uri.https(_fdcBaseUrl, _fdcFoodSearchPath, queryParameters)`, which resolves to:

```
GET https://api.nal.usda.gov/fdc/v1/foods/search
      ?query=<the user's raw search term>
      &pageSize=20
      &dataType=Foundation,SR%20Legacy
      &sortOrder=asc
      &api_key=<FDC_API_KEY>
```

Host `api.nal.usda.gov` is `fdc_const.dart:8`; path `/fdc/v1/foods/search` is `fdc_const.dart:9`; the five query parameters are `fdc_const.dart:11-25` and `fdc_const.dart:169-175`. The user's search term is passed through verbatim as `query`.

The API key **is a single shared project key that identifies this app to USDA**, not a per-user credential. `Env.fdcApiKey` ([`env.dart:7-8`](../lib/core/utils/env.dart)) is an `envied` compile-time field read from `.env` (`FDC_API_KEY`, see `.env.example:2`), and release builds get it from a repository secret: `.github/workflows/default_workflow.yml:653` and `:807` pass `secrets.FDC_API_KEY` into `.github/actions/write-env-file/action.yml:22-33`. So every install of an official build would carry the same key, and USDA would see all traffic as one identified API consumer — the project's. Obfuscation (`obfuscate: true`) hides it from casual strings-dumping, not from the wire.

Note the transport: `Uri.https` forces TLS, so this would not be a cleartext transfer. That is the only mitigating detail, and it is moot given the path is dead.

## The trace, hop by hop

### Hop 1 — the client is constructed and injected (this is real, and it is why the code *looks* live)

- [`locator.dart:527`](../lib/core/utils/locator.dart) — `locator.registerLazySingleton<FDCDataSource>(() => FDCDataSource());`
- [`locator.dart:479`](../lib/core/utils/locator.dart) — `() => ProductsRepository(locator(), locator(), locator())`, the second `locator()` resolving to the `FDCDataSource` above.
- [`products_repository.dart:32`](../lib/features/add_meal/data/repository/products_repository.dart) — held as `final FDCDataSource _fdcDataSource;`, assigned in the constructor at `products_repository.dart:35-39`.

Being a lazy singleton, the instance is not even built until first resolution — and since nothing resolves it beyond the `ProductsRepository` factory, construction is all that ever happens to it. `FDCDataSource`'s constructor performs no I/O ([`fdc_data_source.dart:11-14`](../lib/features/add_meal/data/data_sources/fdc_data_source.dart) is a logger field and a timeout constant).

### Hop 2 — the only method that touches the client

`ProductsRepository` has exactly one method referencing `_fdcDataSource`:

- [`products_repository.dart:105-114`](../lib/features/add_meal/data/repository/products_repository.dart) — `getFDCFoodsByString(String searchString)`, calling `_fdcDataSource.fetchSearchWordResults(searchString)` at `products_repository.dart:106`, mapping via `MealEntity.fromFDCFood` at `:110`.

The repository's other network methods do not touch it:

- `getOFFProductsByString` (`products_repository.dart:41-66`) → `_offDataSource`
- `getSupabaseFoodsByString` (`products_repository.dart:116-127`) → `_spBackendDataSource`
- `getOFFProductByBarcode` (`products_repository.dart:129-133`) → `_offDataSource`

### Hop 3 — the break. Nothing calls `getFDCFoodsByString`

A full-tree search over the `v2.0.2` blob (`git grep -n "getFDCFoodsByString" v2.0.2 -- .`) returns exactly one line: the declaration itself at `products_repository.dart:105`. No caller in `lib/`, none in `test/`, none in `integration_test/`, none in `tool/`, none in any script.

Callers of `ProductsRepository` methods across the whole of `lib/`, exhaustively:

| Call site | Method called | Reaches |
| :-- | :-- | :-- |
| [`search_products_usecase.dart:60`](../lib/features/add_meal/domain/usecase/search_products_usecase.dart) | `getOFFProductsByString` | Open Food Facts |
| [`search_products_usecase.dart:82`](../lib/features/add_meal/domain/usecase/search_products_usecase.dart) | `getSupabaseFoodsByString` | Supabase |
| [`meal_detail_bloc.dart:140`](../lib/features/meal_detail/presentation/bloc/meal_detail_bloc.dart) | `getOFFProductByBarcode` | Open Food Facts |
| [`meal_detail_bloc.dart:199`](../lib/features/meal_detail/presentation/bloc/meal_detail_bloc.dart) | `getOFFProductByBarcode` | Open Food Facts |
| [`search_product_by_barcode_usecase.dart:50`](../lib/features/scanner/domain/usecase/search_product_by_barcode_usecase.dart) | `getOFFProductByBarcode` | Open Food Facts |

`getFDCFoodsByString` appears in no row. That is the whole finding.

### Hop 4 — the decisive line: the "FDC" use case searches Supabase

This is the single line that makes the name misleading and the path dead, and it is where anyone grepping for "FDC" would go wrong:

[`search_products_usecase.dart:72-87`](../lib/features/add_meal/domain/usecase/search_products_usecase.dart)

```dart
Future<SearchProductsResult> searchFDCFoodByString(
  String searchString, {
  bool skipRemote = false,
}) async {
  if (skipRemote) {
    return _buildResult(searchString, const [],
        remoteSkipped: true, cacheSource: MealSourceEntity.fdc);
  }
  final remote = await _safeRemoteCall(
    'FDC',
    () => _productsRepository.getSupabaseFoodsByString(searchString),   // <- line 82
  );
  ...
}
```

The method is called `searchFDCFoodByString`, the log label passed to `_safeRemoteCall` is the string `'FDC'` (`:81`), and the cache tag is `MealSourceEntity.fdc` (`:78`, `:86`) — but the closure at `search_products_usecase.dart:82` calls `getSupabaseFoodsByString`. Every user-visible "FDC" search in the released app is a Supabase query.

`MealEntity.fromSpFood` documents the same aliasing from the other end ([`meal_entity.dart:219-223`](../lib/features/add_meal/domain/entity/meal_entity.dart)): *"All Supabase backend foods keep the fdc source tag ... `fdc` here means 'reference food database' as opposed to OFF/custom"*, because `MealSourceDBO` is persisted in Hive and a per-source enum value would need a data migration. The real origin travels in `backendSource`.

### Hop 5 — bloc and UI, for completeness (they end at Supabase)

- [`food_bloc.dart:43`](../lib/features/add_meal/presentation/bloc/food_bloc.dart) — `RefreshFoodEvent` handler → `searchFDCFoodByString`
- [`food_bloc.dart:86`](../lib/features/add_meal/presentation/bloc/food_bloc.dart) — `_loadFood` (shared by `LoadFoodEvent` and the debounced `SearchFoodInputChangedEvent`, `food_bloc.dart:28-34`) → `searchFDCFoodByString`
- [`locator.dart:285`](../lib/core/utils/locator.dart) — `FoodBloc` factory
- [`add_meal_screen.dart:51`](../lib/features/add_meal/presentation/add_meal_screen.dart) — Add Meal screen resolves `FoodBloc`; the search box is `MealSearchBar` at `add_meal_screen.dart:112-117`, results rendered at `:298-330`, manual refresh at `:142-144`
- [`food_search_tab_view.dart:55`](../lib/features/recipes/presentation/widgets/food_search_tab_view.dart) — the recipe-builder food search resolves the same bloc

Both user-reachable search surfaces therefore terminate at Supabase via hop 4. They never re-enter `ProductsRepository` by any other route.

### Hop 6 — the other candidate paths, checked individually

- **Barcode scan.** [`search_product_by_barcode_usecase.dart:50`](../lib/features/scanner/domain/usecase/search_product_by_barcode_usecase.dart) → `getOFFProductByBarcode` → Open Food Facts only. There is no FDC barcode lookup in the codebase (the `fdc_branded` corpus that carries barcodes lives in Supabase, and its barcode column is `SPConst.foodBarcode`, [`sp_const.dart:27`](../lib/features/add_meal/data/dto/sp/sp_const.dart)).
- **Settings → Food databases.** The toggles filter the Supabase query server-side — [`sp_food_data_source.dart:80-88`](../lib/features/add_meal/data/data_sources/sp_food_data_source.dart) reads them and `:102` / `:176` apply them as `inFilter(SPConst.foodSource, enabledSources)`. Enabling `fdc_foundation` or `fdc_branded` selects **rows in Supabase**, it does not switch on a USDA call. Disabling every source short-circuits to an empty list without any request (`sp_food_data_source.dart:36-39`).
- **Fallback on failure.** `_safeRemoteCall` ([`search_products_usecase.dart:104-118`](../lib/features/add_meal/domain/usecase/search_products_usecase.dart)) catches a failed remote search and returns `const []` — it falls back to *local* results (custom meals, recipes, intake history, the 90-day cache, `search_products_usecase.dart:155-198`). There is no secondary remote source and no retry against a different host. A Supabase outage produces fewer results, never a USDA request.
- **Meal detail / logging an intake.** `HydrateMealEvent` returns immediately unless `meal.source == MealSourceEntity.off` ([`meal_detail_bloc.dart:126-131`](../lib/features/meal_detail/presentation/bloc/meal_detail_bloc.dart)). `_refreshCacheForSelectedMeal` explicitly routes non-OFF meals to a local cache-timestamp touch with no network at all (`meal_detail_bloc.dart:190-197`, and the comment at `:185-189` names FDC as one of the "everything else" cases).
- **Custom food import / QR meal share.** `import_meal_scanner_screen.dart` and `edit_meal_screen.dart` reference `fdc` only as the persisted `MealSourceEntity` enum value; neither holds a `ProductsRepository`.
- **Tests.** [`products_repository_ranking_test.dart:82`](../test/features/add_meal/data/repository/products_repository_ranking_test.dart) constructs a real `FDCDataSource()` to satisfy the constructor's positional argument, then only ever exercises `getOFFProductsByString`. Even the test suite never calls the method.

## The `fdc.nal.usda.gov` URLs are attribution links, not API calls

Easy to conflate with the above; they are a different question and a different (much smaller) disclosure.

There are two distinct USDA hosts in the codebase:

| Constant | Value | Nature |
| :-- | :-- | :-- |
| `FDCConst._fdcBaseUrl` ([`fdc_const.dart:8`](../lib/features/add_meal/data/dto/fdc/fdc_const.dart)) | `api.nal.usda.gov` | The **API**. Unreachable, per the trace above. |
| `FDCConst.fdcWebsiteUrl` ([`fdc_const.dart:5`](../lib/features/add_meal/data/dto/fdc/fdc_const.dart)) | `https://fdc.nal.usda.gov/fdc-app.html#` | A **public website**, opened in the user's browser. |
| `SPConst.foodSourceWebsites` ([`sp_const.dart:105-113`](../lib/features/add_meal/data/dto/sp/sp_const.dart)) | `https://fdc.nal.usda.gov` for the four `fdc_*` sources | Source **attribution**, opened in the user's browser. |

The `sp_const.dart` map is the one flagged in the ticket. It is provenance metadata for rows that were **ingested into Supabase ahead of time** (see [`docs/supabase-self-hosting.md:17-18`](supabase-self-hosting.md)) — it records where a row *came from*, and it is used to build a "learn more" link. It never becomes a request the app makes. `SPConst.fdcSourcePrefix` (`sp_const.dart:57`) exists for the same reason: to decide whether a food has a public detail page worth linking to.

Where those links surface, both via `url_launcher` with `LaunchMode.externalApplication`, i.e. handing the URL to the system browser:

- [`meal_info_button.dart:55-61`](../lib/features/meal_detail/presentation/widgets/meal_info_button.dart) — the info button on a meal detail. For a Supabase FDC food the URL is `MealEntity.url`, built at [`meal_entity.dart:210-212`](../lib/features/add_meal/domain/entity/meal_entity.dart) from `FDCConst.getFoodDetailUrlString(foodItem.sourceCode)` — a `fdc.nal.usda.gov` detail page for the ingested row's original id. Launch at `meal_info_button.dart:94-99`.
- [`food_sources_screen.dart:85-87`](../lib/features/settings/presentation/widgets/food_sources_screen.dart) — the info icon beside each toggle in Settings → Food databases, using `SPConst.foodSourceWebsites`. Launch helper at `food_sources_screen.dart:54-57`.

So: a user who taps an info button causes **their browser** to visit `fdc.nal.usda.gov`. The app itself sends nothing, sends no search term, and sends no key. That is a user-initiated navigation to a public page, of the same kind as the existing Open Food Facts and Sentry-policy links, not a transfer by the app.

(`MealEntity.fromFDCFood` at [`meal_entity.dart:184-200`](../lib/features/add_meal/domain/entity/meal_entity.dart) also builds a `fdc.nal.usda.gov` URL at `:191`, but that factory is only called from `products_repository.dart:110` — inside the dead method — so it never runs either.)

## Feature branch vs. v2.0.2

**No difference.** Diffing `v2.0.2..HEAD` (`6cc0efe8`, `feat/own-server-settings` with the AI-meal-logging feature branch merged in) across `fdc_data_source.dart`, `lib/features/add_meal/data/dto/fdc/`, `products_repository.dart`, `search_products_usecase.dart` and `locator.dart` returns an empty diff — those five files are byte-identical. A fresh grep for `getFDCFoodsByString` on the working tree still finds only the declaration at `products_repository.dart:105`. The unreleased AI work adds providers, but it did not wire up FDC and did not disturb the break at `search_products_usecase.dart:82`.

## What keeps it unreachable — and how fragile that is

Nothing structural. It is unreachable for exactly one reason: **no line of code calls the method.** There is no compile-time guard, no feature flag, no build variant, no `assert`, no dead-code elimination that would complain. Specifically:

- The data source is registered unconditionally at `locator.dart:527`, so it is always available to anything that asks.
- The `FDC_API_KEY` secret is still injected into every official release build (`default_workflow.yml:653`, `:807`), so a live key ships in the binary today.
- Dart's analyzer will not flag `getFDCFoodsByString` as unused: it is a public method on a public class.
- The name collision is actively misleading. A future contributor asked to "make the FDC search work offline-first" would reasonably find `searchFDCFoodByString` and `getFDCFoodsByString` and assume they belong together. Swapping `getSupabaseFoodsByString` for `getFDCFoodsByString` at `search_products_usecase.dart:82` is a one-token edit that would silently make USDA a live recipient on the app's primary search path.

The repo's own docs already record the state — [`AGENTS.md:389`](../AGENTS.md) lists the direct FDC source as *"not actively surfaced in the UI"* and `AGENTS.md:110` says the key is *"not actively used in UI"* — but a note in a contributor guide is not a mechanism.

## What this means for the policy

**USDA FoodData Central is not a live recipient and must not be added to the recipients list.** On `v2.0.2`, and on the current feature-branch HEAD, no user action of any kind causes the app to contact `api.nal.usda.gov`. Adding USDA to the iubenda documents would state a transfer that does not occur — which the map identifies as its own kind of untruth. The live network recipients for search remain Open Food Facts and the Supabase backend, plus Sentry on opt-in.

**The README's claim is accurate as written.** *"Those datasets are ingested into the Supabase backend ahead of time ... so a search reaches that backend and stops there"* ([`README.md:139`](../README.md)) is exactly what the trace shows: the "FDC" search path terminates at Supabase at `search_products_usecase.dart:82`. The "Three destinations, nothing else" table at `README.md:131-137` is complete for the released app. The apparent contradiction that opened this ticket — live-looking wiring at `locator.dart:527` and `products_repository.dart:32` versus the README's claim — resolves in the README's favour: the wiring is real, the call is not.

Two things that are *not* settled by this finding, and belong to the adjudication and rendering tickets rather than here:

1. **The attribution links are a separate, minor question.** Tapping the info button on a meal detail or in Settings → Food databases opens `fdc.nal.usda.gov` in the user's browser (`meal_info_button.dart:94-99`, `food_sources_screen.dart:54-57`). Whether outbound links to third-party websites warrant a mention is a policy-drafting judgement, not a transfer by the app; the same question applies equally to the existing Open Food Facts, BLS, and iubenda links, so it should be decided once for all of them rather than for USDA specially.
2. **A shipped-but-unused key is a code-hygiene finding, not a policy one.** `FDC_API_KEY` is still injected into release builds. Removing the dead method, the data source, its locator registration and the CI secret would close the one-refactor-away gap described above, and would let the "FDC" naming be renamed to something honest (`searchBackendFoodByString`). That is a PR, and per this map's scope it belongs to a ticket of its own.
