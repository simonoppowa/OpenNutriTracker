import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/presentation/widgets/meal_value_unit_text.dart';
import 'package:opennutritracker/core/presentation/widgets/local_user_image.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/energy_display.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_sort_type.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// A logged intake, rendered as a full-width row: a rounded thumbnail, the meal
/// name and amount, and the energy on the trailing edge. Replaces the old
/// 120x120 tile so a day's meals read as a clean scannable list.
class IntakeCard extends StatelessWidget {
  static const double thumbSize = 52;

  final IntakeEntity intake;
  final Function(BuildContext, IntakeEntity)? onItemLongPressed;
  final Function(BuildContext, IntakeEntity, bool)? onItemTapped;
  final VoidCallback? onShare;
  final bool firstListElement;
  final bool usesImperialUnits;
  final DiarySortType? sortType;

  const IntakeCard({
    required super.key,
    required this.intake,
    this.onItemLongPressed,
    this.onItemTapped,
    this.onShare,
    required this.firstListElement,
    required this.usesImperialUnits,
    this.sortType,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(Dimens.radiusM);
    final s = S.of(context);
    final macro = switch (sortType) {
      DiarySortType.protein => (intake.totalProteinsGram, s.proteinLabel),
      DiarySortType.carbs => (intake.totalCarbsGram, s.carbsLabel),
      DiarySortType.fat => (intake.totalFatsGram, s.fatLabel),
      _ => null,
    };
    final macroValue = macro == null
        ? null
        : NumberFormat.decimalPatternDigits(
            locale: Localizations.localeOf(context).toString(),
            decimalDigits: 1,
          ).format(macro.$1);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.spacing16,
        vertical: Dimens.spacing4,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onItemTapped != null
              ? () => onTappedItem(context, usesImperialUnits)
              : null,
          onLongPress: onItemLongPressed != null
              ? () => onLongPressedItem(context)
              : null,
          child: AppCard(
            borderRadius: Dimens.radiusM,
            padding: const EdgeInsets.all(Dimens.spacing12),
            child: Row(
              children: [
                _Thumbnail(intake: intake, palette: palette),
                const SizedBox(width: Dimens.spacing12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        intake.meal.name ?? "?",
                        style: textTheme.titleSmall?.copyWith(color: palette.textStrong),
                        maxLines: 1,
                        minFontSize: 11,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      MealValueUnitText(
                        value: intake.amount,
                        meal: intake.meal,
                        usesImperialUnits: usesImperialUnits,
                        textStyle: textTheme.bodySmall?.copyWith(color: palette.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Dimens.spacing8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (macro != null)
                        Text(
                          '$macroValue ${s.gramUnit} ${macro.$2}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelMedium?.copyWith(
                            color: palette.textStrong,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      Text(
                        EnergyDisplay.formatWithUnit(context, intake.totalKcal),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: macro == null
                            ? textTheme.labelMedium?.copyWith(
                                color: palette.textStrong,
                                fontWeight: FontWeight.w700,
                              )
                            : textTheme.bodySmall?.copyWith(
                                color: palette.textMuted,
                              ),
                      ),
                    ],
                  ),
                ),
                if (onShare != null)
                  Semantics(
                    identifier: 'intake-item-menu',
                    container: true,
                    child: PopupMenuButton<void>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: palette.textMuted,
                      ),
                      shape: Dimens.shapeM,
                      itemBuilder: (_) => [
                        PopupMenuItem<void>(
                          onTap: onShare,
                          child: Semantics(
                            identifier: 'intake-share-food',
                            child: Text(s.shareFoodLabel),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void onLongPressedItem(BuildContext context) {
    onItemLongPressed?.call(context, intake);
  }

  void onTappedItem(BuildContext context, bool usesImperialUnits) {
    onItemTapped?.call(context, intake, usesImperialUnits);
  }
}

/// The leading thumbnail: a user photo, the remote OFF/FDC image, or a soft
/// fallback chip with a food icon — clipped to a rounded square.
class _Thumbnail extends StatefulWidget {
  final IntakeEntity intake;
  final AppPalette palette;

  const _Thumbnail({required this.intake, required this.palette});

  @override
  State<_Thumbnail> createState() => _ThumbnailState();
}

class _ThumbnailState extends State<_Thumbnail> {
  late Stream<int> _changes;
  int _photoRevision = 0;

  void _watchLibrary() {
    final changes = widget.intake.meal.source == MealSourceEntity.recipe
        ? locator<RecipeDataSource>().watch()
        : locator<CustomMealDataSource>().watch();
    _changes = changes.map((_) => ++_photoRevision);
  }

  @override
  void initState() {
    super.initState();
    _watchLibrary();
  }

  @override
  void didUpdateWidget(covariant _Thumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.intake.meal.source != widget.intake.meal.source) {
      _watchLibrary();
    }
  }

  // Resolve only presentation metadata; logged portions and nutrition stay put.
  ({String? local, String? remote}) _photo() {
    final meal = widget.intake.meal;
    if (meal.source == MealSourceEntity.recipe && meal.code != null) {
      final recipe = locator<RecipeDataSource>().getRecipeById(meal.code!);
      if (recipe != null) return (local: recipe.imagePath, remote: null);
    } else if (meal.source != MealSourceEntity.recipe) {
      final identity = meal.code ?? meal.name;
      if (identity != null) {
        for (final current
            in locator<CustomMealDataSource>().getAllCustomMeals()) {
          if (MealSourceEntity.fromMealSourceDBO(current.source) ==
                  meal.source &&
              (current.code ?? current.name) == identity) {
            return (
              local: current.localImagePath,
              remote: current.mainImageUrl,
            );
          }
        }
      }
    }
    return (local: meal.localImagePath, remote: meal.mainImageUrl);
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<int>(
    stream: _changes,
    builder: (context, snapshot) => _buildPhoto(snapshot.data),
  );

  Widget _buildPhoto(int? revision) {
    final photo = _photo();
    Widget content;
    if (photo.local != null) {
      content = LocalUserImage(
        // The picker evicts overwritten bytes, but the slug stays the same.
        key: ValueKey((photo.local, revision)),
        relativePath: photo.local!,
        width: IntakeCard.thumbSize,
        height: IntakeCard.thumbSize,
        placeholder: _fallback(),
      );
    } else if (photo.remote != null) {
      content = CachedNetworkImage(
        cacheManager: locator<CacheManager>(),
        imageUrl: photo.remote!,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => _fallback(),
        placeholder: (context, url) => _fallback(),
      );
    } else {
      content = _fallback();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(Dimens.radiusS),
      child: SizedBox(
        width: IntakeCard.thumbSize,
        height: IntakeCard.thumbSize,
        child: content,
      ),
    );
  }

  Widget _fallback() => Container(
    color: widget.palette.surfaceMuted,
    child: Icon(
      Icons.restaurant_rounded,
      color: widget.palette.textMuted,
      size: 24,
    ),
  );
}
