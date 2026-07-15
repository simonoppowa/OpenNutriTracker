import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/products_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/search_debounce.dart';

/// Controllable fake: each search call returns a future the test completes
/// explicitly, so in-flight cancellation by the restartable transformer can
/// be simulated deterministically.
class _FakeSearchProductsUseCase implements SearchProductsUseCase {
  final List<Completer<SearchProductsResult>> calls = [];
  final List<String> queries = [];

  @override
  Future<SearchProductsResult> searchOFFProductsByString(
    String searchString, {
    bool skipRemote = false,
  }) {
    queries.add(searchString);
    final completer = Completer<SearchProductsResult>();
    calls.add(completer);
    return completer.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetConfigUsecase implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(true, true, false, AppThemeEntity.system);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

const _emptyResult = SearchProductsResult(
  meals: [],
  remoteSourceEmpty: true,
);

/// Waits out the search debounce plus a small margin so the bloc's handler
/// has started.
Future<void> _settleDebounce() async {
  await Future<void>.delayed(
    searchDebounceDuration + const Duration(milliseconds: 100),
  );
}

void main() {
  group('ProductsBloc search dedup', () {
    late _FakeSearchProductsUseCase useCase;
    late ProductsBloc bloc;

    setUp(() {
      useCase = _FakeSearchProductsUseCase();
      bloc = ProductsBloc(useCase, _FakeGetConfigUsecase());
    });

    tearDown(() => bloc.close());

    test(
        'a duplicate debounced event while the first search is in flight '
        'still produces results (regression: the duplicate cancelled the '
        'in-flight handler and then no-oped on the stale dedup guard, so no '
        'search ever completed)', () async {
      bloc.add(const SearchInputChangedEvent(searchString: 'apple'));
      await _settleDebounce();
      expect(useCase.calls, hasLength(1),
          reason: 'first search should be in flight');

      // Same final text arrives again (e.g. a char typed and deleted within
      // the debounce window) — restartable cancels the in-flight handler.
      bloc.add(const SearchInputChangedEvent(searchString: 'apple'));
      await _settleDebounce();

      // The replacement handler must have started a new search rather than
      // dropping the query as "already searched".
      expect(useCase.calls.length, greaterThanOrEqualTo(2),
          reason: 'the duplicate event must restart the search');
      useCase.calls.last.complete(_emptyResult);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state, isA<ProductsLoadedState>());
    });

    test('retyping the same query after a failed search retries it',
        () async {
      bloc.add(const SearchInputChangedEvent(searchString: 'apple'));
      await _settleDebounce();
      useCase.calls.single.completeError(Exception('HTTP 500'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state, isA<ProductsFailedState>());

      bloc.add(const SearchInputChangedEvent(searchString: 'apple'));
      await _settleDebounce();

      expect(useCase.calls, hasLength(2),
          reason: 'a failed query must not be remembered as completed');
      useCase.calls.last.complete(_emptyResult);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state, isA<ProductsLoadedState>());
    });

    test('a completed query is not searched again for the same text',
        () async {
      bloc.add(const SearchInputChangedEvent(searchString: 'apple'));
      await _settleDebounce();
      useCase.calls.single.complete(_emptyResult);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state, isA<ProductsLoadedState>());

      bloc.add(const SearchInputChangedEvent(searchString: 'apple'));
      await _settleDebounce();

      expect(useCase.calls, hasLength(1),
          reason: 'results for this query are already on screen');
    });

    test(
        'a new search over an empty result list blanks to the loading state '
        'instead of leaving "no results" on screen, and loaded states carry '
        'their query', () async {
      bloc.add(const SearchInputChangedEvent(searchString: 'xyzzy'));
      await _settleDebounce();
      useCase.calls.single.complete(_emptyResult);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final loaded = bloc.state;
      expect(loaded, isA<ProductsLoadedState>());
      expect((loaded as ProductsLoadedState).query, 'xyzzy');
      expect(loaded.products, isEmpty);

      // New query while the visible list is empty: the stale empty Loaded
      // state must not linger (it renders as "no results").
      bloc.add(const SearchInputChangedEvent(searchString: 'banana'));
      await _settleDebounce();
      expect(bloc.state, isA<ProductsLoadingState>(),
          reason: 'empty results must blank to a spinner during the search');

      useCase.calls.last.complete(_emptyResult);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect((bloc.state as ProductsLoadedState).query, 'banana');
    });

    test('a blank query never queries any source and resets to Initial',
        () async {
      // Get some results on screen first.
      bloc.add(const SearchInputChangedEvent(searchString: 'apple'));
      await _settleDebounce();
      useCase.calls.single.complete(_emptyResult);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state, isA<ProductsLoadedState>());

      // Chip taps and tab switches force-submit the current field text —
      // with an empty field that must not become a remote query.
      bloc.add(const LoadProductsEvent(searchString: ''));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(useCase.calls, hasLength(1),
          reason: 'an empty query must not hit the search use case');
      expect(bloc.state, isA<ProductsInitial>());

      // Whitespace-only input counts as empty too (debounced path).
      bloc.add(const SearchInputChangedEvent(searchString: '   '));
      await _settleDebounce();
      expect(useCase.calls, hasLength(1));
      expect(bloc.state, isA<ProductsInitial>());
    });

    test(
        'input below the minimum query length does not trigger a search; '
        'reaching it does', () async {
      // One character — below minQueryLength: nothing may be queried, even
      // on the forced submit path.
      bloc.add(const SearchInputChangedEvent(searchString: 'a'));
      await _settleDebounce();
      bloc.add(const LoadProductsEvent(searchString: 'a'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(useCase.calls, isEmpty);
      expect(bloc.state, isA<ProductsInitial>());

      // Two characters — at the threshold: the search runs.
      bloc.add(const SearchInputChangedEvent(searchString: 'ap'));
      await _settleDebounce();
      expect(useCase.calls, hasLength(1));
      expect(useCase.queries.single, 'ap');
      useCase.calls.single.complete(_emptyResult);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state, isA<ProductsLoadedState>());
    });
  });
}
