// PROTOTYPE — throwaway. Answers "what should the Support page look like?"
// for map #1526 / ticket #1532. Lives on branch prototype/support-page only;
// never merge to main. Strings are hard-coded English on purpose.
import 'package:flutter/material.dart';

enum ProtoPlatform { ios, android }

/// The tip jar's states, cycled from the floating bar so each can be judged.
enum TipState { loading, loaded, failed, tipped }

/// The seven ways to help, in no particular order — each variant decides
/// order and grouping itself.
enum SupportWayId { tip, rate, share, star, translate, report, code }

class SupportWay {
  final SupportWayId id;
  final IconData icon;
  final String title;
  final String subtitle;

  /// Rough effort, for variants that group by time.
  final String effort; // 'seconds' | 'minute' | 'evening'
  /// Rough kind, for variants that group by what is given.
  final String kind; // 'money' | 'word' | 'skills'

  /// What tapping does, shown in a snackbar in the prototype.
  final String Function(ProtoPlatform) target;

  const SupportWay({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.effort,
    required this.kind,
    required this.target,
  });
}

class TipProduct {
  final String name;
  final String price; // as the store would format it
  const TipProduct(this.name, this.price);
}

const tipProducts = [
  TipProduct('Small tip', '€1.99'),
  TipProduct('Medium tip', '€4.99'),
  TipProduct('Large tip', '€9.99'),
];

const repoUrl = 'https://github.com/simonoppowa/OpenNutriTracker';
const iosStoreUrl = 'https://apps.apple.com/app/id6451490901';
const playStoreUrl =
    'https://play.google.com/store/apps/details?id=com.opennutritracker.ont.opennutritracker';

final supportWays = <SupportWay>[
  SupportWay(
    id: SupportWayId.tip,
    icon: Icons.volunteer_activism_rounded,
    title: 'Leave a tip',
    subtitle:
        'A one-time tip through the store. Unlocks nothing — it just helps.',
    effort: 'minute',
    kind: 'money',
    target: (p) => p == ProtoPlatform.ios
        ? 'App Store purchase sheet (In-App Purchase, consumable)'
        : 'Google Play purchase sheet (Play Billing, consumable)',
  ),
  SupportWay(
    id: SupportWayId.rate,
    icon: Icons.star_rate_rounded,
    title: 'Rate the app',
    subtitle: 'A rating helps others find OpenNutriTracker.',
    effort: 'minute',
    kind: 'word',
    target: (p) => p == ProtoPlatform.ios
        ? '$iosStoreUrl?action=write-review'
        : '$playStoreUrl (listing, external app)',
  ),
  SupportWay(
    id: SupportWayId.share,
    icon: Icons.ios_share_rounded,
    title: 'Share with a friend',
    subtitle: 'Send a link through any app.',
    effort: 'seconds',
    kind: 'word',
    target: (p) =>
        'System share sheet: "OpenNutriTracker — a free, open-source nutrition tracker. '
        'iPhone: $iosStoreUrl  Android: $playStoreUrl"',
  ),
  SupportWay(
    id: SupportWayId.star,
    icon: Icons.star_outline_rounded,
    title: 'Star on GitHub',
    subtitle: 'Show the project some love where developers look.',
    effort: 'seconds',
    kind: 'word',
    target: (_) => repoUrl,
  ),
  SupportWay(
    id: SupportWayId.translate,
    icon: Icons.translate_rounded,
    title: 'Help translate',
    subtitle: 'Translate in your browser on Weblate. No coding needed.',
    effort: 'evening',
    kind: 'skills',
    target: (_) => 'https://hosted.weblate.org/engage/opennutritracker/',
  ),
  SupportWay(
    id: SupportWayId.report,
    icon: Icons.lightbulb_outline_rounded,
    title: 'Report a bug or idea',
    subtitle: 'Open an issue on GitHub. Others can see and vote on it.',
    effort: 'minute',
    kind: 'skills',
    target: (_) => '$repoUrl/issues/new/choose',
  ),
  SupportWay(
    id: SupportWayId.code,
    icon: Icons.code_rounded,
    title: 'Contribute code',
    subtitle: 'Flutter and Dart. Start with the contributing guide.',
    effort: 'evening',
    kind: 'skills',
    target: (_) => '$repoUrl/blob/main/CONTRIBUTING.md',
  ),
];

/// Everything a variant needs. Variants only render; the screen owns state.
class SupportProtoModel {
  final ProtoPlatform platform;
  final TipState tipState;
  final void Function(SupportWay way) onWayTap;
  final void Function(TipProduct tip) onTip;
  final VoidCallback onRetry;

  const SupportProtoModel({
    required this.platform,
    required this.tipState,
    required this.onWayTap,
    required this.onTip,
    required this.onRetry,
  });

  SupportWay way(SupportWayId id) => supportWays.firstWhere((w) => w.id == id);

  /// The one-line notice shown instead of the tip rows when products fail.
  String get tipFailureText =>
      "Couldn't load tips. Tips work in the App Store and Google Play versions of the app.";

  /// The quiet on-device line shown after a tip.
  String get tippedText => 'You left a tip — thank you!';

  /// Header line, deliberately without guilt-tripping.
  String get whyText =>
      'OpenNutriTracker is free, ad-free and open source, built by volunteers. '
      'If it helps you, here are a few ways to help it back.';
}
