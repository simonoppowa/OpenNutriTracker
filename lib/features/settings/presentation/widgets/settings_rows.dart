import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/presentation/widgets/badged_title.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';

// The building blocks of a Settings-style screen: muted category headers
// over cards of rows. Shared by the Settings screen and the Support page so
// the two look the same.

/// The small muted header above each [SettingsGroup].
class SettingsCategoryHeader extends StatelessWidget {
  final AppPalette palette;
  final String label;

  const SettingsCategoryHeader({
    super.key,
    required this.palette,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimens.spacing12,
        Dimens.spacing4,
        Dimens.spacing12,
        Dimens.spacing8,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: palette.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Wraps a run of related settings rows inside one [AppCard], with a hairline
/// divider between rows. Gives the screen the same calm grouped rhythm as the
/// Profile tab rather than one long ungrouped list.
class SettingsGroup extends StatelessWidget {
  final AppPalette palette;
  final List<Widget> tiles;

  const SettingsGroup({super.key, required this.palette, required this.tiles});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      if (i > 0) {
        rows.add(Divider(height: Dimens.hairline, color: palette.border));
      }
      rows.add(tiles[i]);
    }
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: Dimens.spacing4),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

/// A single settings row. Keeps the underlying [ListTile] (so its role
/// semantics carry through) and an optional [Semantics] identifier where the
/// original markup carried one, but dresses the leading icon as a soft
/// rounded chip in the friendly-flat style.
class SettingsTile extends StatelessWidget {
  final String? identifier;
  final AppPalette palette;
  final IconData icon;
  final Color? iconColor;
  final Color? titleColor;
  final String title;
  final String? subtitle;

  /// A short status word shown beside the title, e.g. "Experimental".
  final String? badge;

  /// Bounds the title to one line with an ellipsis. Settings rows leave their
  /// titles free to wrap; the Support page's rows are one-liners.
  final bool singleLineTitle;
  final Widget? trailing;
  final bool showChevron;
  final bool enabled;

  /// Null for a row that only labels what sits below it.
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.palette,
    required this.icon,
    required this.title,
    required this.onTap,
    this.identifier,
    this.iconColor,
    this.titleColor,
    this.subtitle,
    this.badge,
    this.singleLineTitle = false,
    this.trailing,
    this.showChevron = false,
    this.enabled = true,
  });

  /// The title, with [badge] beside it when one is set.
  ///
  /// The overflow discipline moved into [BadgedTitle] for #728, when
  /// onboarding needed the same marker — it is a rule rather than a layout,
  /// and re-deriving it at a second site was the obvious way to get it subtly
  /// wrong. The typography stays here, so a settings row still looks like a
  /// settings row.
  Widget _title(TextTheme text) {
    final style = text.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: titleColor,
    );
    if (singleLineTitle && badge == null) {
      return Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    return BadgedTitle(
      title: title,
      badge: badge,
      palette: palette,
      style: style,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final text = Theme.of(context).textTheme;
    final tint = iconColor ?? accent;
    final tile = ListTile(
      enabled: enabled,
      leading: SettingsIconChip(palette: palette, icon: icon, color: tint),
      title: _title(text),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: text.bodyMedium?.copyWith(color: palette.textMuted),
            )
          : null,
      trailing:
          trailing ??
          (showChevron
              ? Icon(Icons.chevron_right_rounded, color: accent)
              : null),
      onTap: onTap,
    );
    if (identifier == null) return tile;
    return Semantics(identifier: identifier!, child: tile);
  }
}

/// The soft rounded leading chip shared by every settings row.
class SettingsIconChip extends StatelessWidget {
  final AppPalette palette;
  final IconData icon;
  final Color color;

  const SettingsIconChip({
    super.key,
    required this.palette,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: Dimens.borderRadiusS,
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
