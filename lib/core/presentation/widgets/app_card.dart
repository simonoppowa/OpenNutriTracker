import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';

/// The one card surface of the friendly-flat design: a rounded tile with a
/// hairline border and a single soft, low shadow. Quiet depth — enough to lift
/// content off the warm canvas without the heaviness of clay or stacked elevation.
///
/// Pass [color] for a tinted tile (e.g. a macro card); the border and shadow
/// adapt to the active light/dark palette.
class AppCard extends StatelessWidget {
  final Widget? child;
  final Color? color;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool bordered;

  const AppCard({
    super.key,
    this.child,
    this.color,
    this.borderRadius = Dimens.radiusL,
    this.padding,
    this.width,
    this.height,
    this.onTap,
    this.bordered = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final radius = BorderRadius.circular(borderRadius);
    final tile = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? palette.surface,
        borderRadius: radius,
        border: bordered ? Border.all(color: palette.border, width: Dimens.hairline) : null,
        boxShadow: [
          BoxShadow(color: palette.shadow, blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      // A transparent Material directly below the colored decoration so any
      // descendant ListTile/InkWell paints on this ancestor rather than
      // reaching past the decoration for one further up the tree. Clipped to
      // the card radius so descendant ink splashes/highlights stay within the
      // rounded corners instead of painting square past them.
      //
      // The Material must span the whole card, with [padding] applied inside
      // it — not on the Container around it. Padding the Container instead
      // shrinks the Material to the content box while the clip keeps the
      // card's full radius, so the corner arc curves in over the content and
      // takes a bite out of anything flush against the edge. That clipped the
      // first glyph of left-aligned text sitting in a card corner, e.g. the
      // "374/428 g" totals in the home macro tiles.
      child: child == null
          ? null
          : Material(
              color: Colors.transparent,
              borderRadius: radius,
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: padding ?? EdgeInsets.zero,
                child: child,
              ),
            ),
    );
    if (onTap == null) return tile;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(borderRadius: radius, onTap: onTap, child: tile),
    );
  }
}
