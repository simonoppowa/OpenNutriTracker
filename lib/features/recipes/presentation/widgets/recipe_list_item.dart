import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/utils/energy_display.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/user_image_storage.dart';
import 'package:opennutritracker/generated/l10n.dart';

class RecipeListItem extends StatelessWidget {
  final RecipeEntity recipe;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;

  const RecipeListItem({
    super.key,
    required this.recipe,
    required this.onTap,
    this.onLongPress,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final kcalPer100 = recipe.aggregatedNutrimentsPer100.energyKcal100;
    final totalKcal = (kcalPer100 ?? 0) * recipe.totalWeightG / 100;
    final ingredientCount = recipe.ingredients.length;

    // Derive a thumbnail from the first ingredient that has one. Falls back
    // to a generic recipe icon when none of the ingredients carry imagery
    // (e.g. all-custom-meal recipes from the FDC source).
    final thumbnailUrl = recipe.ingredients
        .map((i) => i.snapshotMeal.thumbnailImageUrl)
        .firstWhere((url) => url != null && url.isNotEmpty, orElse: () => null);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: ListTile(
        onLongPress: onLongPress,
        leading: isSelected
            ? CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Icon(
                  Icons.check,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              )
            : recipe.imagePath != null
                ? _UserImageThumbnail(relativePath: recipe.imagePath!)
                : thumbnailUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  cacheManager: locator<CacheManager>(),
                  fit: BoxFit.cover,
                  width: 40,
                  height: 40,
                  imageUrl: thumbnailUrl,
                  errorWidget: (context, url, error) => CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.menu_book,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              )
            : CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.menu_book,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
        title: Text(
          recipe.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${S.of(context).recipeIngredientCountLabel(ingredientCount)} · '
          '${EnergyDisplay.formatWithUnit(context, totalKcal)}',
        ),
        trailing: isSelected ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _UserImageThumbnail extends StatelessWidget {
  final String relativePath;

  const _UserImageThumbnail({required this.relativePath});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: UserImageStorage.absolutePath(relativePath),
      builder: (context, snapshot) {
        final fallback = CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.menu_book,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        );
        if (!snapshot.hasData) return fallback;
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            File(snapshot.data!),
            fit: BoxFit.cover,
            width: 40,
            height: 40,
            errorBuilder: (_, error, stack) => fallback,
          ),
        );
      },
    );
  }
}
