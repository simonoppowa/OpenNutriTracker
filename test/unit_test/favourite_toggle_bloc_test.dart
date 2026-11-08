import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/favourite_toggle_bloc.dart';

import '../helpers/fake_favourites.dart';

MealEntity _meal(String code, {bool detailed = false}) => MealEntity(
  code: code,
  name: 'Meal $code',
  url: null,
  mealQuantity: '100',
  mealUnit: 'g',
  servingQuantity: detailed ? 30 : null,
  servingUnit: detailed ? 'g' : null,
  servingSize: null,
  nutriments: MealNutrimentsEntity.empty(),
  source: MealSourceEntity.fdc,
  detailed: detailed,
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

  test(
    'a hydration landing during a pending star keeps the full record',
    () async {
      // The star is tapped on the thin search result, and the detail page's
      // fetch lands while that write is still pending. Run beside the toggle,
      // the hydration would find nothing starred yet and do nothing, and the
      // toggle would then store the thin record for good.
      favourites.slowWrites = true;
      final thin = _meal('9');
      bloc.add(LoadFavouriteStatusEvent(thin));
      expect(await settle(), isFalse);

      bloc
        ..add(ToggleFavouriteEvent(thin))
        ..add(FavouriteMealHydratedEvent(_meal('9', detailed: true)));
      for (var i = 0; i < 5; i++) {
        await settle();
      }

      expect(favourites.stored(thin)?.detailed, isTrue);
      expect(bloc.state.isFavourite, isTrue);
    },
  );

  test('a row rebound during a pending toggle shows its new food', () async {
    // The write for A lands a turn later; meanwhile the recycled row is
    // handed B, which is not a favourite. A's result must not show on B.
    favourites.slowWrites = true;
    final shown = <bool>[];
    final sub = bloc.stream.listen((state) => shown.add(state.isFavourite));
    final a = _meal('7');
    final b = _meal('8');
    bloc.add(LoadFavouriteStatusEvent(a));
    await settle();

    bloc
      ..add(ToggleFavouriteEvent(a))
      ..add(LoadFavouriteStatusEvent(b));
    for (var i = 0; i < 5; i++) {
      await settle();
    }
    await sub.cancel();

    expect(favourites.contains(a), isTrue);
    expect(bloc.state.isFavourite, isFalse);
    expect(shown, isNot(contains(true)));
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
