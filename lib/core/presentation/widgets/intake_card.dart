import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/meal_value_unit_text.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/user_image_storage.dart';

class IntakeCard extends StatelessWidget {
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
    return Row(
      children: [
        SizedBox(width: firstListElement ? 16 : 0),
        SizedBox(
          width: 120,
          height: 120,
          child: Card(
            semanticContainer: true,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            elevation: 1,
            child: InkWell(
              onLongPress: onItemLongPressed != null
                  ? () => onLongPressedItem(context)
                  : null,
              onTap: onItemTapped != null
                  ? () => onTappedItem(context, usesImperialUnits)
                  : null,
              child: Stack(
                children: [
                  // Prefer the user-attached local photo for custom meals
                  // (#64 follow-up). Falls through to the OFF / FDC remote
                  // image when the user hasn't picked one, and finally to
                  // the placeholder icon for entries that have neither.
                  if (intake.meal.localImagePath != null)
                    _LocalMealBackground(
                        relativePath: intake.meal.localImagePath!)
                  else if (intake.meal.mainImageUrl != null)
                    CachedNetworkImage(
                      cacheManager: locator<CacheManager>(),
                      imageUrl: intake.meal.mainImageUrl ?? "",
                      imageBuilder: (context, imageProvider) => Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Icon(
                        Icons.restaurant_outlined,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  Container(
                    // Add color shade
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(8.0),
                    padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.tertiaryContainer.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${intake.totalKcal.toInt()} kcal',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onTertiaryContainer,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          intake.meal.name ?? "?",
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        MealValueUnitText(
                          value: intake.amount,
                          meal: intake.meal,
                          usesImperialUnits: usesImperialUnits,
                          textStyle: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer
                                    .withValues(alpha: 0.7),
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
      ],
    );
  }

  void onLongPressedItem(BuildContext context) {
    onItemLongPressed?.call(context, intake);
  }

  void onTappedItem(BuildContext context, bool usesImperialUnits) {
    onItemTapped?.call(context, intake, usesImperialUnits);
  }
}

/// Renders a user-attached meal photo behind the intake-card overlay.
/// Mirrors the `CachedNetworkImage` branch's BoxFit / decoration so the
/// card's gradient + kcal pill sit on top exactly as they did before.
class _LocalMealBackground extends StatelessWidget {
  final String relativePath;

  const _LocalMealBackground({required this.relativePath});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: UserImageStorage.absolutePath(relativePath),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final file = File(snapshot.data!);
        if (!file.existsSync()) return const SizedBox.shrink();
        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: FileImage(file),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}
