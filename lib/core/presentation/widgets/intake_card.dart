import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/presentation/widgets/meal_value_unit_text.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/energy_display.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/user_image_storage.dart';

/// A logged intake, rendered as a full-width row: a rounded thumbnail, the meal
/// name and amount, and the energy on the trailing edge. Replaces the old
/// 120x120 tile so a day's meals read as a clean scannable list.
class IntakeCard extends StatelessWidget {
  static const double thumbSize = 52;

  final IntakeEntity intake;
  final Function(BuildContext, IntakeEntity)? onItemLongPressed;
  final Function(BuildContext, IntakeEntity, bool)? onItemTapped;
  final bool firstListElement;
  final bool usesImperialUnits;

  const IntakeCard({
    required super.key,
    required this.intake,
    this.onItemLongPressed,
    this.onItemTapped,
    required this.firstListElement,
    required this.usesImperialUnits,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(Dimens.radiusM);
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
                      Text(
                        intake.meal.name ?? "?",
                        style: textTheme.titleSmall?.copyWith(color: palette.textStrong),
                        maxLines: 1,
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
                Text(
                  EnergyDisplay.formatWithUnit(context, intake.totalKcal),
                  style: textTheme.labelMedium?.copyWith(
                    color: palette.textStrong,
                    fontWeight: FontWeight.w700,
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
class _Thumbnail extends StatelessWidget {
  final IntakeEntity intake;
  final AppPalette palette;

  const _Thumbnail({required this.intake, required this.palette});

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (intake.meal.localImagePath != null) {
      content = _LocalMealImage(relativePath: intake.meal.localImagePath!);
    } else if (intake.meal.mainImageUrl != null) {
      content = CachedNetworkImage(
        cacheManager: locator<CacheManager>(),
        imageUrl: intake.meal.mainImageUrl ?? "",
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
        color: palette.surfaceMuted,
        child: Icon(Icons.restaurant_rounded, color: palette.textMuted, size: 24),
      );
}

class _LocalMealImage extends StatelessWidget {
  final String relativePath;

  const _LocalMealImage({required this.relativePath});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: UserImageStorage.absolutePath(relativePath),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final file = File(snapshot.data!);
        if (!file.existsSync()) return const SizedBox.shrink();
        return Image.file(file, fit: BoxFit.cover);
      },
    );
  }
}
