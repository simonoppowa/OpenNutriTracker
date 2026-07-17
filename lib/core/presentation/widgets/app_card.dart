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
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? palette.surface,
        borderRadius: radius,
        border: bordered ? Border.all(color: palette.border, width: Dimens.hairline) : null,
        boxShadow: [
          BoxShadow(color: palette.shadow, blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );
    if (onTap == null) return tile;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(borderRadius: radius, onTap: onTap, child: tile),
    );
  }
}
