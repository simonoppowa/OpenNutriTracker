import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_placeholder.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Asks whether [product], found for a store-internal barcode, is the one
/// the user scanned (#83): true for yes, false for no.
Future<bool> showStoreProductConfirmDialog(
  BuildContext context,
  MealEntity product,
) async {
  final l10n = S.of(context);
  final textTheme = Theme.of(context).textTheme;
  final answer = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.storeCodeConfirmTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: Dimens.borderRadiusM,
            child: CachedNetworkImage(
              width: 120,
              height: 120,
              cacheManager: locator<CacheManager>(),
              imageUrl: product.mainImageUrl ?? product.thumbnailImageUrl ?? '',
              fit: BoxFit.cover,
              placeholder: (_, _) => const MealPlaceholder(),
              errorWidget: (_, _, _) => const MealPlaceholder(),
            ),
          ),
          const SizedBox(height: Dimens.spacing12),
          Text(
            product.name ?? '',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium,
          ),
          if (product.brands != null && product.brands!.isNotEmpty)
            Text(
              product.brands!,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
          const SizedBox(height: Dimens.spacing12),
          Text(l10n.storeCodeConfirmBody, style: textTheme.bodySmall),
        ],
      ),
      actions: [
        Semantics(
          identifier: 'scanner-store-code-no',
          child: TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.storeCodeConfirmNo),
          ),
        ),
        Semantics(
          identifier: 'scanner-store-code-yes',
          child: FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.storeCodeConfirmYes),
          ),
        ),
      ],
    ),
  );
  return answer ?? false;
}
