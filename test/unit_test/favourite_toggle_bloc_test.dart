import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/favourite_toggle_bloc.dart';

import '../helpers/fake_favourites.dart';

MealEntity _meal(String code) => MealEntity(
  code: code,
  name: 'Meal $code',
  url: null,
  mealQuantity: '100',
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: null,
  servingSize: null,
  nutriments: MealNutrimentsEntity.empty(),
  source: MealSourceEntity.fdc,
);

void main() {
  late FakeFavourites favourites;
  late FavouriteToggleBloc bloc;

  setUp(() {
    favourites = FakeFavourites();
    bloc = FavouriteToggleBloc(favourites.get, favourites.toggle);
  });

  tearDown(() async {
    await bloc.close();
    await favourites.dispose();
  });

  Future<bool> settle() async {
    await Future<void>.delayed(Duration.zero);
    return bloc.state.isFavourite;
  }

  test('reads whether the meal is already a favourite', () async {
    favourites.add(_meal('1'));

    bloc.add(LoadFavouriteStatusEvent(_meal('1')));

    expect(await settle(), isTrue);
  });

  test('toggling stars and then unstars the meal', () async {
    final meal = _meal('2');
    bloc.add(LoadFavouriteStatusEvent(meal));
    expect(await settle(), isFalse);

    bloc.add(ToggleFavouriteEvent(meal));
    expect(await settle(), isTrue);
    expect(favourites.contains(meal), isTrue);

    bloc.add(ToggleFavouriteEvent(meal));
    expect(await settle(), isFalse);
    expect(favourites.contains(meal), isFalse);
  });

  test('a double tap lands back where it started', () async {
    // Each toggle reads the stored state before writing it. Run side by
    // side, the second tap would read the list before the first one's write
    // landed and star the meal a second time instead of unstarring it.
    favourites.slowWrites = true;
    final meal = _meal('6');
    bloc.add(LoadFavouriteStatusEvent(meal));
    expect(await settle(), isFalse);

    bloc
      ..add(ToggleFavouriteEvent(meal))
      ..add(ToggleFavouriteEvent(meal));
    for (var i = 0; i < 5; i++) {
      await settle();
    }

    expect(favourites.contains(meal), isFalse);
    expect(bloc.state.isFavourite, isFalse);
  });

  test('follows a toggle made by another star', () async {
    final meal = _meal('3');
    bloc.add(LoadFavouriteStatusEvent(meal));
    await settle();

    // The same food starred on its detail page.
    favourites.add(meal);

    expect(await settle(), isTrue);
  });

  test('another food starred elsewhere leaves this star alone', () async {
    bloc.add(LoadFavouriteStatusEvent(_meal('4')));
    await settle();

    favourites.add(_meal('5'));

    expect(await settle(), isFalse);
  });
}
