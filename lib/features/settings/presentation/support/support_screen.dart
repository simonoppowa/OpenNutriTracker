import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/app_const.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/safe_url_launcher.dart';
import 'package:opennutritracker/features/settings/domain/entity/tip_entity.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/tip_jar_cubit.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/settings_rows.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:share_plus/share_plus.dart';

/// Support OpenNutriTracker: seven ways to help the app, reached only from
/// Settings → About (#1536). Spread the word, give your skills, or leave a
/// tip through the store.
///
/// Nothing here nudges: no prompt, banner or timer leads to this page, and
/// "Rate the app" opens the store listing rather than the native review
/// prompt (#1531).
class SupportScreen extends StatefulWidget {
  /// Defaults to the app-wide tip jar started in `main`.
  final TipJarCubit? tipJar;
  final SharePlus? sharePlus;
  final UrlOpener openUrl;

  const SupportScreen({
    super.key,
    this.tipJar,
    this.sharePlus,
    this.openUrl = tryLaunchExternalUrl,
  });

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  late final TipJarCubit _tipJar;
  late final StreamSubscription<TipOutcome> _outcomes;
  final GlobalKey _shareRowKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tipJar = widget.tipJar ?? locator<TipJarCubit>();
    _outcomes = _tipJar.outcomes.listen(_onOutcome);
    _tipJar.load();
  }

  @override
  void dispose() {
    _outcomes.cancel();
    super.dispose();
  }

  void _open(String url) =>
      openUrlOrShowError(context, url, open: widget.openUrl);

  /// iOS opens the App Store's write-a-review form. Play has no documented
  /// link to its review form, so Android opens the listing (#1531).
  void _rate() {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    _open(isIOS ? AppConst.appStoreReviewUrl : AppConst.playStoreUrl);
  }

  Future<void> _share() async {
    final l10n = S.of(context);
    final box = _shareRowKey.currentContext?.findRenderObject() as RenderBox?;
    // iPad anchors the share sheet's popover here, and fails without it.
    final origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    final links = l10n.supportShareLinks(
      AppConst.appStoreUrl,
      AppConst.playStoreUrl,
    );
    await (widget.sharePlus ?? SharePlus.instance).share(
      ShareParams(
        text: '${l10n.appDescription}\n\n$links',
        sharePositionOrigin: origin,
      ),
    );
  }

  void _onOutcome(TipOutcome outcome) {
    if (!mounted) return;
    final l10n = S.of(context);
    switch (outcome) {
      case TipThanked(:final tip):
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.supportTipThanksTitle),
            content: Text(
              l10n.supportTipThanksBody(tipName(l10n, tip.size), tip.price),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.dialogOKLabel),
              ),
            ],
          ),
        );
      case TipPending():
        _showSnackBar(l10n.supportTipPending);
      case TipFailed():
        _showSnackBar(l10n.supportTipFailed);
    }
  }

  /// Clears first: Play can report one failure both from the purchase call
  /// and on the purchase stream, and it should read as one message.
  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;

    SettingsTile way({
      Key? key,
      required String identifier,
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) => SettingsTile(
      key: key,
      identifier: identifier,
      palette: palette,
      icon: icon,
      title: title,
      subtitle: subtitle,
      singleLineTitle: true,
      showChevron: true,
      onTap: onTap,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsSupportLabel)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Dimens.spacing16,
          Dimens.spacing8,
          Dimens.spacing16,
          Dimens.spacing32,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Dimens.spacing12,
              Dimens.spacing8,
              Dimens.spacing12,
              Dimens.spacing20,
            ),
            child: Text(
              l10n.supportHeader,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.textMuted),
            ),
          ),
          SettingsCategoryHeader(
            palette: palette,
            label: l10n.supportGroupSpreadWord,
          ),
          SettingsGroup(
            palette: palette,
            tiles: [
              way(
                identifier: 'support-way-rate',
                icon: Icons.star_rate_rounded,
                title: l10n.supportRateTitle,
                subtitle: l10n.supportRateSubtitle,
                onTap: _rate,
              ),
              way(
                key: _shareRowKey,
                identifier: 'support-way-share',
                icon: Icons.ios_share_rounded,
                title: l10n.supportShareTitle,
                subtitle: l10n.supportShareSubtitle,
                onTap: _share,
              ),
              way(
                identifier: 'support-way-star',
                icon: Icons.star_outline_rounded,
                title: l10n.supportStarTitle,
                subtitle: l10n.supportStarSubtitle,
                onTap: () => _open(AppConst.sourceCodeUrl),
              ),
            ],
          ),
          const SizedBox(height: Dimens.spacing20),
          SettingsCategoryHeader(
            palette: palette,
            label: l10n.supportGroupSkills,
          ),
          SettingsGroup(
            palette: palette,
            tiles: [
              way(
                identifier: 'support-way-translate',
                icon: Icons.translate_rounded,
                title: l10n.supportTranslateTitle,
                subtitle: l10n.supportTranslateSubtitle,
                onTap: () => _open(AppConst.translateUrl),
              ),
              way(
                identifier: 'support-way-report',
                icon: Icons.lightbulb_outline_rounded,
                title: l10n.supportReportTitle,
                subtitle: l10n.supportReportSubtitle,
                onTap: () => _open(AppConst.newIssueUrl),
              ),
              way(
                identifier: 'support-way-code',
                icon: Icons.code_rounded,
                title: l10n.supportCodeTitle,
                subtitle: l10n.supportCodeSubtitle,
                onTap: () => _open(AppConst.contributingUrl),
              ),
            ],
          ),
          const SizedBox(height: Dimens.spacing20),
          SettingsCategoryHeader(
            palette: palette,
            label: l10n.supportGroupMoney,
          ),
          SettingsGroup(
            palette: palette,
            tiles: [_TipBlock(palette: palette, tipJar: _tipJar)],
          ),
        ],
      ),
    );
  }
}

/// The chip and dialog name of a tip.
String tipName(S l10n, TipSize size) => switch (size) {
  TipSize.small => l10n.supportTipSmall,
  TipSize.medium => l10n.supportTipMedium,
  TipSize.large => l10n.supportTipLarge,
};

/// "Leave a tip": a heading row that only labels, with the tip jar's state
/// underneath.
class _TipBlock extends StatelessWidget {
  final AppPalette palette;
  final TipJarCubit tipJar;

  const _TipBlock({required this.palette, required this.tipJar});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsTile(
          palette: palette,
          icon: Icons.volunteer_activism_rounded,
          title: l10n.supportTipTitle,
          subtitle: l10n.supportTipSubtitle,
          singleLineTitle: true,
          onTap: null,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimens.spacing16,
            Dimens.spacing4,
            Dimens.spacing16,
            Dimens.spacing12,
          ),
          child: BlocBuilder<TipJarCubit, TipJarState>(
            bloc: tipJar,
            builder: (context, state) => _tipArea(context, state),
          ),
        ),
      ],
    );
  }

  Widget _tipArea(BuildContext context, TipJarState state) {
    final l10n = S.of(context);
    final muted = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: palette.textMuted);
    final Widget body = switch (state.status) {
      TipJarStatus.loading => const SizedBox(
        height: 56,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      TipJarStatus.failed => Row(
        children: [
          Expanded(child: Text(l10n.supportTipLoadFailed, style: muted)),
          const SizedBox(width: Dimens.spacing8),
          Semantics(
            identifier: 'support-tip-retry',
            child: TextButton(
              onPressed: tipJar.load,
              child: Text(l10n.retryLabel),
            ),
          ),
        ],
      ),
      TipJarStatus.ready => Row(
        children: [
          for (var i = 0; i < state.tips.length; i++) ...[
            if (i > 0) const SizedBox(width: Dimens.spacing8),
            Expanded(
              child: _TipChip(
                palette: palette,
                tip: state.tips[i],
                onPressed: () => tipJar.buy(state.tips[i]),
              ),
            ),
          ],
        ],
      ),
    };
    // Text only, on purpose: a badge, icon or theme would be an unlock under
    // App Review 3.1.1 and change what the tip is (#1534).
    if (!state.hasTipped || state.status == TipJarStatus.loading) return body;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body,
        const SizedBox(height: Dimens.spacing12),
        Text(l10n.supportTipLeft, style: muted),
      ],
    );
  }
}

class _TipChip extends StatelessWidget {
  final AppPalette palette;
  final TipEntity tip;
  final VoidCallback onPressed;

  const _TipChip({
    required this.palette,
    required this.tip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final text = Theme.of(context).textTheme;
    // `container: true`: the parent is an Expanded, which would otherwise
    // hand this node the whole row's bounds (AGENTS.md).
    return Semantics(
      identifier: 'support-tip-${tip.size.name}',
      container: true,
      child: OutlinedButton(
        onPressed: onPressed,
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
              tipName(S.of(context), tip.size),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelMedium?.copyWith(color: palette.textMuted),
            ),
            const SizedBox(height: 2),
            Text(
              tip.price,
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
    );
  }
}
