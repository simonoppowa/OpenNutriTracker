import 'package:collection/collection.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/search/brand_query.dart';
import 'package:opennutritracker/features/add_meal/util/meal_relevance_ranker.dart';

/// The fork's ordering on top of upstream's search ranking (#41): products
/// of a brand or store the query names come right after the user's own
/// entries, and in the merged list a local BLS food goes ahead of an Open
/// Food Facts product that matches about as well.
class SearchOrdering {
  /// How much relevance a BLS food gets on top, enough to win a tie or a
  /// near tie and not more.
  static const blsBonus = 0.05;

  /// [meals] with the products of the brands [query] names after the own
  /// entries (custom foods, recipes) and before the rest; each group keeps
  /// its order.
  static List<MealEntity> brandFirst(List<MealEntity> meals, String query) {
    final brands = BrandQuery.parse(query);
    if (!brands.hasBrands) return meals;
    final own = meals.where(_isOwn);
    final branded = meals.where(
      (meal) => !_isOwn(meal) && brands.matchesBrands(meal.brands),
    );
    final rest = meals.where(
      (meal) => !_isOwn(meal) && !brands.matchesBrands(meal.brands),
    );
    return [...own, ...branded, ...rest];
  }

  /// The merged "All" list: [brandFirst], with the rest ordered by relevance
  /// to the product words where BLS foods get [blsBonus].
  static List<MealEntity> rankMerged(List<MealEntity> meals, String query) {
    final brands = BrandQuery.parse(query);
    final text = brands.hasBrands ? brands.text : query;
    final ordered = brandFirst(meals, query);
    final lead = ordered
        .takeWhile((meal) => _isOwn(meal) || brands.matchesBrands(meal.brands))
        .toList();
    final rest = [
      for (final meal in ordered.skip(lead.length))
        (meal: meal, score: scoreMealRelevance(meal, text) + _bonus(meal)),
    ];
    mergeSort(rest, compare: (a, b) => b.score.compareTo(a.score));
    return [...lead, for (final entry in rest) entry.meal];
  }

  static double _bonus(MealEntity meal) =>
      meal.backendSource == SPConst.blsSourceCode ? blsBonus : 0;

  static bool _isOwn(MealEntity meal) =>
      meal.source == MealSourceEntity.custom ||
      meal.source == MealSourceEntity.recipe;
}
