import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';

/// The label above a run of related settings rows. Quiet, wide-tracked and
/// bolder than body text, so a section reads as a heading and not as another
/// row of content.
///
/// Extracted from the Profile screen so onboarding can present its options
/// the same way as the screens the user lands on afterwards.
class SectionHeader extends StatelessWidget {
  final String label;

  /// Defaults to the palette for the active brightness; pass one only when
  /// the caller has already resolved it.
  final AppPalette? palette;

  const SectionHeader({super.key, required this.label, this.palette});

  @override
  Widget build(BuildContext context) {
    final resolved =
        palette ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppPalette.dark
            : AppPalette.light);
    return Padding(
      padding: const EdgeInsets.only(left: Dimens.spacing4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: resolved.textMuted,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Wraps a run of related rows inside one [AppCard] so they read as a single
/// surface, with a hairline divider between rows rather than between cards.
class SectionGroup extends StatelessWidget {
  final List<Widget> tiles;
  final AppPalette? palette;

  const SectionGroup({super.key, required this.tiles, this.palette});

  @override
  Widget build(BuildContext context) {
    final resolved =
        palette ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppPalette.dark
            : AppPalette.light);
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      if (i > 0) {
        rows.add(Divider(height: Dimens.hairline, color: resolved.border));
      }
      rows.add(tiles[i]);
    }
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: Dimens.spacing4),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}
