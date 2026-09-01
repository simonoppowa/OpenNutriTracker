import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';

/// A small muted pill for a word about a feature's *state* rather than its
/// name — "Experimental" being the one this exists for.
///
/// Muted rather than accented on purpose: this is a statement about the
/// feature's stability, not a call to action, and an accent-coloured pill
/// beside a title reads as "new — try this".
class MutedBadge extends StatelessWidget {
  final String text;

  /// Defaults to the palette for the active brightness; pass one only when
  /// the caller has already resolved it.
  final AppPalette? palette;

  const MutedBadge({super.key, required this.text, this.palette});

  @override
  Widget build(BuildContext context) {
    final resolved =
        palette ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppPalette.dark
            : AppPalette.light);
    final muted = resolved.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: muted.withValues(alpha: 0.12),
        borderRadius: Dimens.borderRadiusS,
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: muted, height: 1.2),
      ),
    );
  }
}

/// A row title with an optional [MutedBadge] beside it.
///
/// Shared rather than duplicated because it carries a rule, not a layout.
/// Follows AGENTS.md's "Row titles must not overflow": the title is
/// line-bounded, so it ellipsizes rather than silently wrapping — the thing
/// that rule is actually about.
///
/// **A `Wrap`, not a `Row`, and that is a fix rather than a preference.** As a
/// `Row` this bounded the title with `Flexible` and left the badge at its
/// intrinsic width, on the reasoning that "Experimental" ellipsized to
/// "Exper…" says nothing while a clipped title is still recognisable. Both
/// halves of that are right; the conclusion did not survive measurement.
/// Constraining only the title cannot help when the *badge alone* is wider
/// than the row: at 2x text scale in German on a 320px phone, "Experimentell"
/// overflowed the onboarding row by **79 pixels** no matter how far the title
/// shrank. Ellipsis has no answer to that and neither does `Flexible`.
///
/// `Wrap` does: the badge moves to its own line instead of off the screen,
/// and nothing is truncated in the one case where truncating was the only
/// option a `Row` had. At ordinary text sizes both still sit on one line, so
/// the layout is unchanged where it already fitted.
///
/// **Untouched when there is no badge**: that path is a bare `Text` outside
/// any multi-child layout, so rows without a badge keep wrapping as they
/// always have.
///
/// [style] is the caller's, so a settings row and an onboarding row keep their
/// own typography while sharing the constraint. Extracted for #728, when
/// onboarding needed the same marker and re-deriving the bound by hand was the
/// obvious way to get it subtly wrong — which is exactly what the measurement
/// above then caught in the original.
class BadgedTitle extends StatelessWidget {
  final String title;
  final String? badge;
  final TextStyle? style;
  final AppPalette? palette;

  const BadgedTitle({
    super.key,
    required this.title,
    this.badge,
    this.style,
    this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final badgeText = badge;
    if (badgeText == null) return Text(title, style: style);

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Text(
          title,
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        MutedBadge(text: badgeText, palette: palette),
      ],
    );
  }
}
