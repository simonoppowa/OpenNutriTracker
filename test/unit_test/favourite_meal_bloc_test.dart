import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/favourite_meal_bloc.dart';

import '../helpers/fake_favourites.dart';

class _FakeGetConfigUsecase implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(true, true, false, AppThemeEntity.system);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

MealEntity _meal(String code, String name, {String? brands}) => MealEntity(
  code: code,
  name: name,
  brands: brands,
  url: null,
  mealQuantity: '100',
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: null,
  servingSize: null,
  nutriments: MealNutrimentsEntity.empty(),
  source: MealSourceEntity.off,
);

List<String?> _names(FavouriteMealState state) =>
    (state as FavouriteMealLoadedState).favourites.map((m) => m.name).toList();

void main() {
  late FakeFavourites favourites;
  late FavouriteMealBloc bloc;

  setUp(() {
    favourites = FakeFavourites();
    bloc = FavouriteMealBloc(favourites.get, _FakeGetConfigUsecase());
  });

  tearDown(() async {
    await bloc.close();
    await favourites.dispose();
  });

  test('loads every favourite for an empty query', () async {
    favourites
      ..add(_meal('1', 'Oats'))
      ..add(_meal('2', 'Skyr'));

    bloc.add(const LoadFavouriteMealEvent(searchString: ''));

    await expectLater(
      bloc.stream,
      emitsInOrder([
        isA<FavouriteMealLoadingState>(),
        isA<FavouriteMealLoadedState>(),
      ]),
    );
    expect(_names(bloc.state), ['Skyr', 'Oats']);
  });

  test('filters by name and brand, ignoring case', () async {
    favourites
      ..add(_meal('1', 'Oats'))
      ..add(_meal('2', 'Yoghurt', brands: 'Skyrella'))
      ..add(_meal('3', 'Bread'));

    bloc.add(const LoadFavouriteMealEvent(searchString: ' sKyR '));
    await bloc.stream.firstWhere((s) => s is FavouriteMealLoadedState);

    expect(_names(bloc.state), ['Yoghurt']);
  });

  test('an empty list is a loaded state, not a failure', () async {
    bloc.add(const LoadFavouriteMealEvent(searchString: ''));
    await bloc.stream.firstWhere((s) => s is FavouriteMealLoadedState);

    expect(_names(bloc.state), isEmpty);
  });

  test('follows a star toggled elsewhere, keeping the query', () async {
    favourites.add(_meal('1', 'Oat milk'));
    bloc.add(const LoadFavouriteMealEvent(searchString: 'oat'));
    await bloc.stream.firstWhere((s) => s is FavouriteMealLoadedState);

    // Starred on the detail page while this list sits under it.
    favourites
      ..add(_meal('2', 'Oatcakes'))
      ..add(_meal('3', 'Rice'));

    await bloc.stream.firstWhere(
      (s) => s is FavouriteMealLoadedState && s.favourites.length == 2,
    );
    expect(_names(bloc.state), ['Oatcakes', 'Oat milk']);
  });

  test('a change before the first load does not load on its own', () async {
    favourites.add(_meal('1', 'Oats'));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state, isA<FavouriteMealInitial>());
  });

  test('a failed read is reported', () async {
    favourites.readError = StateError('box closed');

    bloc.add(const LoadFavouriteMealEvent(searchString: ''));

    await expectLater(
      bloc.stream,
      emitsInOrder([
        isA<FavouriteMealLoadingState>(),
        isA<FavouriteMealFailedState>(),
      ]),
    );
  });
}
