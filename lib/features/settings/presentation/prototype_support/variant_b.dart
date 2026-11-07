// PROTOTYPE — throwaway. Variant B: Tip jar hero + grid.
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/features/settings/presentation/prototype_support/support_prototype_data.dart';

/// Money first: a tip-jar hero card with three big price cards, then the other
/// six ways as a two-column grid of square tiles. No list rows anywhere.
class SupportVariantB extends StatelessWidget {
  final SupportProtoModel model;

  const SupportVariantB({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
    final text = Theme.of(context).textTheme;
    final others = supportWays.where((w) => w.id != SupportWayId.tip).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Dimens.spacing16,
        Dimens.spacing16,
        Dimens.spacing16,
        140,
      ),
      children: [
        _TipJarHero(model: model, palette: palette),
        const SizedBox(height: Dimens.spacing24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimens.spacing4),
          child: Text(
            'Other ways to help',
            style: text.titleSmall?.copyWith(
              color: palette.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: Dimens.spacing12),
        _WayGrid(ways: others, model: model, palette: palette),
      ],
    );
  }
}

class _TipJarHero extends StatelessWidget {
  final SupportProtoModel model;
  final AppPalette palette;

  const _TipJarHero({required this.model, required this.palette});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final text = Theme.of(context).textTheme;
    final tipWay = model.way(SupportWayId.tip);

    return AppCard(
      padding: const EdgeInsets.all(Dimens.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.favorite_rounded, size: 52, color: accent),
            ),
          ),
          const SizedBox(height: Dimens.spacing16),
          Text(
            model.whyText,
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(color: palette.textStrong),
          ),
          const SizedBox(height: Dimens.spacing20),
          Row(
            children: [
              Icon(tipWay.icon, size: 20, color: accent),
              const SizedBox(width: Dimens.spacing8),
              Expanded(
                child: Text(
                  tipWay.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimens.spacing4),
          Text(
            tipWay.subtitle,
            style: text.bodyMedium?.copyWith(color: palette.textMuted),
          ),
          const SizedBox(height: Dimens.spacing16),
          _TipArea(model: model, palette: palette),
        ],
      ),
    );
  }
}

class _TipArea extends StatelessWidget {
  final SupportProtoModel model;
  final AppPalette palette;

  const _TipArea({required this.model, required this.palette});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final text = Theme.of(context).textTheme;

    switch (model.tipState) {
      case TipState.loading:
        return const SizedBox(
          height: 112,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        );
      case TipState.failed:
        return Row(
          children: [
            Expanded(
              child: Text(
                model.tipFailureText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium?.copyWith(color: palette.textMuted),
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
      case TipState.tipped:
        final cards = <Widget>[];
        for (var i = 0; i < tipProducts.length; i++) {
          if (i > 0) cards.add(const SizedBox(width: Dimens.spacing8));
          cards.add(
            Expanded(
              child: _TipPriceCard(
                product: tipProducts[i],
                // Medium is the visually emphasised default.
                emphasised: i == 1,
                onTap: () => model.onTip(tipProducts[i]),
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: cards,
              ),
            ),
            if (model.tipState == TipState.tipped) ...[
              const SizedBox(height: Dimens.spacing12),
              Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 18, color: accent),
                  const SizedBox(width: Dimens.spacing8),
                  Expanded(
                    child: Text(
                      model.tippedText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
    }
  }
}

class _TipPriceCard extends StatelessWidget {
  final TipProduct product;
  final bool emphasised;
  final VoidCallback onTap;

  const _TipPriceCard({
    required this.product,
    required this.emphasised,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final onAccent = Theme.of(context).colorScheme.onPrimary;
    final text = Theme.of(context).textTheme;
    final fg = emphasised ? onAccent : accent;
    final id = 'support-${product.name.toLowerCase().replaceAll(' ', '-')}';

    // Parent is Expanded, so `container: true` keeps the node's bounds tight.
    return Semantics(
      identifier: id,
      container: true,
      child: AppCard(
        borderRadius: Dimens.radiusM,
        color: emphasised ? accent : accent.withValues(alpha: 0.10),
        bordered: !emphasised,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: Dimens.spacing8,
          vertical: Dimens.spacing16,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                product.name.replaceAll(' tip', ''),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Dimens.spacing4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  product.price,
                  maxLines: 1,
                  style: text.headlineSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WayGrid extends StatelessWidget {
  final List<SupportWay> ways;
  final SupportProtoModel model;
  final AppPalette palette;

  const _WayGrid({
    required this.ways,
    required this.model,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    const gap = Dimens.spacing12;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Tiles are at least square; they grow taller at large text scales
        // instead of overflowing, and both tiles in a row match heights.
        final side = (constraints.maxWidth - gap) / 2;
        final rows = <Widget>[];
        for (var i = 0; i < ways.length; i += 2) {
          if (i > 0) rows.add(const SizedBox(height: gap));
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _tile(ways[i], side)),
                  const SizedBox(width: gap),
                  Expanded(
                    child: i + 1 < ways.length
                        ? _tile(ways[i + 1], side)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }

  Widget _tile(SupportWay way, double side) => _WayTile(
    way: way,
    palette: palette,
    minHeight: side,
    onTap: () => model.onWayTap(way),
  );
}

class _WayTile extends StatelessWidget {
  final SupportWay way;
  final AppPalette palette;
  final double minHeight;
  final VoidCallback onTap;

  const _WayTile({
    required this.way,
    required this.palette,
    required this.minHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final text = Theme.of(context).textTheme;

    // Parent is Expanded, so `container: true` keeps the node's bounds tight.
    return Semantics(
      identifier: 'support-way-${way.id.name}',
      container: true,
      child: AppCard(
        borderRadius: Dimens.radiusM,
        onTap: onTap,
        padding: const EdgeInsets.all(Dimens.spacing16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: minHeight - 2 * Dimens.spacing16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(Dimens.radiusS),
                ),
                child: Icon(way.icon, color: accent, size: 24),
              ),
              const Spacer(),
              const SizedBox(height: Dimens.spacing12),
              Text(
                way.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: Dimens.spacing4),
              Text(
                way.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(color: palette.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
