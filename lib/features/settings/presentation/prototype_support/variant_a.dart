// PROTOTYPE — throwaway. Variant A: Settings-style list.
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/features/settings/presentation/prototype_support/support_prototype_data.dart';

/// Reads like a continuation of the Settings screen: a short header line, then
/// grouped cards per kind of help ("Give money", "Spread the word", "Give your
/// skills"), each row dressed like a settings row.
class SupportVariantA extends StatelessWidget {
  final SupportProtoModel model;

  const SupportVariantA({super.key, required this.model});

  static const _groups = <(String kind, String label)>[
    ('money', 'Give money'),
    ('word', 'Spread the word'),
    ('skills', 'Give your skills'),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
    final text = Theme.of(context).textTheme;

    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(
          Dimens.spacing12,
          Dimens.spacing8,
          Dimens.spacing12,
          Dimens.spacing20,
        ),
        child: Text(
          model.whyText,
          style: text.bodyMedium?.copyWith(color: palette.textMuted),
        ),
      ),
    ];

    for (var g = 0; g < _groups.length; g++) {
      final (kind, label) = _groups[g];
      final ways = supportWays.where((w) => w.kind == kind).toList();
      if (ways.isEmpty) continue;
      if (g > 0) children.add(const SizedBox(height: Dimens.spacing20));
      children.add(_CategoryHeader(palette: palette, label: label));
      children.add(
        _Group(
          palette: palette,
          tiles: [
            for (final way in ways)
              way.id == SupportWayId.tip
                  ? _TipBlock(palette: palette, way: way, model: model)
                  : _WayTile(
                      palette: palette,
                      way: way,
                      onTap: () => model.onWayTap(way),
                    ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Dimens.spacing16,
        Dimens.spacing8,
        Dimens.spacing16,
        140,
      ),
      children: children,
    );
  }
}

/// Muted small header above each card, matching Settings' category headers.
class _CategoryHeader extends StatelessWidget {
  final AppPalette palette;
  final String label;

  const _CategoryHeader({required this.palette, required this.label});

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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: palette.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// One AppCard holding a run of rows with hairline dividers (copy of
/// Settings' private _SettingsGroup).
class _Group extends StatelessWidget {
  final AppPalette palette;
  final List<Widget> tiles;

  const _Group({required this.palette, required this.tiles});

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

/// Soft rounded leading icon chip (copy of Settings' _SettingsIconChip).
class _IconChip extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconChip({required this.icon, required this.color});

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

/// A tappable way-to-help row in the Settings row style.
class _WayTile extends StatelessWidget {
  final AppPalette palette;
  final SupportWay way;
  final VoidCallback onTap;

  const _WayTile({
    required this.palette,
    required this.way,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final text = Theme.of(context).textTheme;
    return Semantics(
      identifier: 'support-way-${way.id.name}',
      child: ListTile(
        leading: _IconChip(icon: way.icon, color: accent),
        title: Text(
          way.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          way.subtitle,
          style: text.bodyMedium?.copyWith(color: palette.textMuted),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: accent),
        onTap: onTap,
      ),
    );
  }
}

/// The tip way: an untappable heading row, then the tip area underneath,
/// which follows [SupportProtoModel.tipState].
class _TipBlock extends StatelessWidget {
  final AppPalette palette;
  final SupportWay way;
  final SupportProtoModel model;

  const _TipBlock({
    required this.palette,
    required this.way,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: _IconChip(icon: way.icon, color: accent),
          title: Text(
            way.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            way.subtitle,
            style: text.bodyMedium?.copyWith(color: palette.textMuted),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimens.spacing16,
            Dimens.spacing4,
            Dimens.spacing16,
            Dimens.spacing12,
          ),
          child: _tipArea(context, accent, text),
        ),
      ],
    );
  }

  Widget _tipArea(BuildContext context, Color accent, TextTheme text) {
    switch (model.tipState) {
      case TipState.loading:
        return const SizedBox(
          height: 56,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      case TipState.failed:
        return Row(
          children: [
            Expanded(
              child: Text(
                model.tipFailureText,
                style: text.bodySmall?.copyWith(color: palette.textMuted),
              ),
            ),
            const SizedBox(width: Dimens.spacing8),
            Semantics(
              identifier: 'support-tip-retry',
              child: TextButton(
                onPressed: model.onRetry,
                child: const Text('Retry'),
              ),
            ),
          ],
        );
      case TipState.loaded:
        return _tipChips(accent, text);
      case TipState.tipped:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _tipChips(accent, text),
            const SizedBox(height: Dimens.spacing12),
            Row(
              children: [
                Icon(Icons.favorite_rounded, size: 16, color: accent),
                const SizedBox(width: Dimens.spacing8),
                Expanded(
                  child: Text(
                    model.tippedText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: palette.textMuted),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  Widget _tipChips(Color accent, TextTheme text) {
    return Row(
      children: [
        for (var i = 0; i < tipProducts.length; i++) ...[
          if (i > 0) const SizedBox(width: Dimens.spacing8),
          Expanded(
            child: Semantics(
              identifier:
                  'support-tip-${tipProducts[i].name.split(' ').first.toLowerCase()}',
              child: OutlinedButton(
                onPressed: () => model.onTip(tipProducts[i]),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimens.spacing8,
                    vertical: Dimens.spacing8,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: Dimens.borderRadiusS,
                  ),
                  side: BorderSide(color: palette.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tipProducts[i].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelMedium?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tipProducts[i].price,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
