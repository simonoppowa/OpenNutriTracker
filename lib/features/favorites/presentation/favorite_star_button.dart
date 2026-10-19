import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/favorites/domain/favorites_usecase.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// A star in a detail screen's app bar that marks the food or recipe as a
/// favourite (#38) and shows at once whether it is one.
class FavoriteStarButton extends StatefulWidget {
  final MealEntity? meal;
  final RecipeEntity? recipe;
  final String semanticsId;
  final FavoritesUsecase? usecase;

  const FavoriteStarButton.meal(MealEntity this.meal, {super.key, this.usecase})
    : recipe = null,
      semanticsId = 'meal-detail-favorite';

  const FavoriteStarButton.recipe(
    RecipeEntity this.recipe, {
    super.key,
    this.usecase,
  }) : meal = null,
       semanticsId = 'recipe-detail-favorite';

  @override
  State<FavoriteStarButton> createState() => _FavoriteStarButtonState();
}

class _FavoriteStarButtonState extends State<FavoriteStarButton> {
  late final FavoritesUsecase _favorites =
      widget.usecase ?? locator<FavoritesUsecase>();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _favorites.changes.addListener(_refresh);
  }

  @override
  void dispose() {
    _favorites.changes.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool get _isFavorite {
    final meal = widget.meal;
    return meal != null
        ? _favorites.isMealFavorite(meal)
        : _favorites.isRecipeFavorite(widget.recipe!.id);
  }

  Future<void> _toggle() async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final meal = widget.meal;
      final nowFavorite = meal != null
          ? await _favorites.toggleMeal(meal)
          : await _favorites.toggleRecipe(widget.recipe!);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              nowFavorite ? s.favoriteAddedLabel : s.favoriteRemovedLabel,
            ),
          ),
        );
    } catch (error, stackTrace) {
      Logger(
        'FavoriteStarButton',
      ).warning('Could not change the favourite', error, stackTrace);
      messenger.showSnackBar(SnackBar(content: Text(s.favoriteToggleFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final favorite = _isFavorite;
    return Semantics(
      identifier: widget.semanticsId,
      toggled: favorite,
      child: IconButton(
        tooltip: favorite ? s.favoriteRemoveTooltip : s.favoriteAddTooltip,
        icon: Icon(
          favorite ? Icons.star_rounded : Icons.star_outline_rounded,
          color: favorite ? Theme.of(context).colorScheme.primary : null,
        ),
        onPressed: _busy ? null : _toggle,
      ),
    );
  }
}
