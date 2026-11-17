import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';

/// One tile of the Trends overview: a metric's name, its headline for the
/// range, and a tap that opens the metric's page.
class TrendsTile extends StatelessWidget {
  /// The tile's test and automation handle, also its widget key.
  final String id;
  final String title;
  final Widget child;
  final VoidCallback onTap;

  const TrendsTile({
    super.key,
    required this.id,
    required this.title,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final text = Theme.of(context).textTheme;
    // The tile sits in an Expanded, so the node needs its own bounds.
    return Semantics(
      identifier: id,
      container: true,
      button: true,
      child: AppCard(
        key: ValueKey(id),
        padding: const EdgeInsets.all(Dimens.spacing16),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: text.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: palette.textMuted),
              ],
            ),
            const SizedBox(height: Dimens.spacing8),
            child,
          ],
        ),
      ),
    );
  }
}

/// A tile's headline: a value and, under it, what the value is.
class TrendsTileValue extends StatelessWidget {
  final String value;
  final String? caption;

  const TrendsTileValue({super.key, required this.value, this.caption});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: text.titleLarge?.copyWith(
            color: palette.textStrong,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (caption != null)
          Text(
            caption!,
            style: text.bodySmall?.copyWith(color: palette.textMuted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
