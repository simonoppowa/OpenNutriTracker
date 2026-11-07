// PROTOTYPE — throwaway. Variant C: Effort ladder.
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/features/settings/presentation/prototype_support/support_prototype_data.dart';

/// Ways grouped by how much time the user has: seconds, a minute, an evening.
/// Each way is a collapsed card that expands into a short explanation and one
/// call to action (or, for the tip way, the three tip buttons).
class SupportVariantC extends StatelessWidget {
  final SupportProtoModel model;

  const SupportVariantC({super.key, required this.model});

  static const _sections = [
    (effort: 'seconds', title: 'Got 10 seconds?', icon: Icons.bolt_rounded),
    (effort: 'minute', title: 'Got a minute?', icon: Icons.timer_outlined),
    (effort: 'evening', title: 'Got an evening?', icon: Icons.nightlight_round),
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
          Dimens.spacing4,
          Dimens.spacing8,
          Dimens.spacing4,
          Dimens.spacing8,
        ),
        child: Text(
          model.whyText,
          style: text.bodyLarge?.copyWith(
            color: palette.textMuted,
            height: 1.4,
          ),
        ),
      ),
    ];

    for (final section in _sections) {
      final ways = supportWays.where((w) => w.effort == section.effort);
      children.add(
        _SectionHeader(
          palette: palette,
          icon: section.icon,
          title: section.title,
        ),
      );
      for (final way in ways) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: Dimens.spacing12),
            child: _EffortCard(
              key: ValueKey(way.id),
              palette: palette,
              way: way,
              body: way.id == SupportWayId.tip
                  ? _TipBody(palette: palette, model: model, way: way)
                  : _ActionBody(palette: palette, model: model, way: way),
            ),
          ),
        );
      }
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

/// One rung of the ladder: a small icon and a time question.
class _SectionHeader extends StatelessWidget {
  final AppPalette palette;
  final IconData icon;
  final String title;

  const _SectionHeader({
    required this.palette,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimens.spacing4,
        Dimens.spacing20,
        Dimens.spacing4,
        Dimens.spacing12,
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(width: Dimens.spacing8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

/// An expandable card, collapsed by default. The header row toggles it.
class _EffortCard extends StatefulWidget {
  final AppPalette palette;
  final SupportWay way;
  final Widget body;

  const _EffortCard({
    super.key,
    required this.palette,
    required this.way,
    required this.body,
  });

  @override
  State<_EffortCard> createState() => _EffortCardState();
}

class _EffortCardState extends State<_EffortCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final text = Theme.of(context).textTheme;
    final palette = widget.palette;
    final way = widget.way;

    final header = Semantics(
      identifier: 'support-way-${way.id.name}',
      button: true,
      expanded: _expanded,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(Dimens.spacing16),
          child: Row(
            children: [
              _IconChip(icon: way.icon, color: accent),
              const SizedBox(width: Dimens.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      way.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      way.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Dimens.spacing8),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: AppMotion.durationShort,
                curve: AppMotion.standard,
                child: Icon(Icons.expand_more_rounded, color: accent),
              ),
            ],
          ),
        ),
      ),
    );

    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          AnimatedSize(
            duration: AppMotion.durationMedium,
            curve: AppMotion.emphasized,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Divider(height: Dimens.hairline, color: palette.border),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Dimens.spacing16,
                          Dimens.spacing12,
                          Dimens.spacing16,
                          Dimens.spacing16,
                        ),
                        child: widget.body,
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// Expanded body for a non-tip way: a sentence or two and one button.
class _ActionBody extends StatelessWidget {
  final AppPalette palette;
  final SupportProtoModel model;
  final SupportWay way;

  const _ActionBody({
    required this.palette,
    required this.model,
    required this.way,
  });

  String get _explanation => switch (way.id) {
    SupportWayId.share =>
      'Most people find OpenNutriTracker through a friend. '
          'This opens your share sheet with a link for iPhone and Android.',
    SupportWayId.star =>
      'Stars help the project show up in GitHub search and tell new '
          'contributors it is alive. Opens the repository in your browser.',
    SupportWayId.rate =>
      'A rating and a sentence or two in the store help others decide to '
          'try the app.',
    SupportWayId.report =>
      'Found something broken or have an idea? Open an issue on GitHub — '
          'others can add details and vote on it.',
    SupportWayId.translate =>
      'Translations happen in your browser on Weblate. Pick your language '
          'and translate a few strings at a time — no coding needed.',
    SupportWayId.code =>
      'The app is built with Flutter and Dart. The contributing guide '
          'covers setup and where to start.',
    SupportWayId.tip => way.subtitle,
  };

  String get _cta => switch (way.id) {
    SupportWayId.share => 'Share the app',
    SupportWayId.star => 'Open GitHub',
    SupportWayId.rate =>
      model.platform == ProtoPlatform.ios
          ? 'Rate on the App Store'
          : 'Rate on Google Play',
    SupportWayId.report => 'Open an issue',
    SupportWayId.translate => 'Open Weblate',
    SupportWayId.code => 'Read the guide',
    SupportWayId.tip => 'Leave a tip',
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _explanation,
          style: text.bodyMedium?.copyWith(color: palette.textMuted),
        ),
        const SizedBox(height: Dimens.spacing12),
        Semantics(
          identifier: 'support-way-${way.id.name}-cta',
          child: FilledButton(
            onPressed: () => model.onWayTap(way),
            child: Text(_cta, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }
}

/// Expanded body for the tip way: the tip buttons, or a state line instead.
class _TipBody extends StatelessWidget {
  final AppPalette palette;
  final SupportProtoModel model;
  final SupportWay way;

  const _TipBody({
    required this.palette,
    required this.model,
    required this.way,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final accent = Theme.of(context).colorScheme.primary;
    final muted = text.bodyMedium?.copyWith(color: palette.textMuted);

    final Widget tips = switch (model.tipState) {
      TipState.loading => const Padding(
        padding: EdgeInsets.symmetric(vertical: Dimens.spacing12),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ),
      TipState.failed => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(model.tipFailureText, style: muted),
          const SizedBox(height: Dimens.spacing4),
          Semantics(
            identifier: 'support-tip-retry',
            child: TextButton(
              onPressed: model.onRetry,
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
      TipState.loaded || TipState.tipped => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final tip in tipProducts) ...[
            _TipButton(model: model, tip: tip),
            if (tip != tipProducts.last)
              const SizedBox(height: Dimens.spacing8),
          ],
          if (model.tipState == TipState.tipped) ...[
            const SizedBox(height: Dimens.spacing12),
            Row(
              children: [
                Icon(Icons.favorite_rounded, color: accent, size: 16),
                const SizedBox(width: Dimens.spacing8),
                Expanded(
                  child: Text(
                    model.tippedText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pick an amount. The store handles payment; nothing in the app '
          'changes.',
          style: muted,
        ),
        const SizedBox(height: Dimens.spacing12),
        tips,
      ],
    );
  }
}

/// One tip as a full-width button: name on the left, store price on the right.
class _TipButton extends StatelessWidget {
  final SupportProtoModel model;
  final TipProduct tip;

  const _TipButton({required this.model, required this.tip});

  @override
  Widget build(BuildContext context) {
    final size = tip.name.split(' ').first.toLowerCase();
    return Semantics(
      identifier: 'support-tip-$size',
      child: FilledButton.tonal(
        onPressed: () => model.onTip(tip),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(Dimens.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: Dimens.spacing16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                tip.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: Dimens.spacing8),
            Text(
              tip.price,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft rounded leading chip, copied from the settings screen's icon chip.
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
