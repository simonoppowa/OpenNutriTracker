// PROTOTYPE — throwaway. See support_prototype_data.dart.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/features/settings/presentation/prototype_support/support_prototype_data.dart';
import 'package:opennutritracker/features/settings/presentation/prototype_support/variant_a.dart';
import 'package:opennutritracker/features/settings/presentation/prototype_support/variant_b.dart';
import 'package:opennutritracker/features/settings/presentation/prototype_support/variant_c.dart';

class SupportPrototypeScreen extends StatefulWidget {
  const SupportPrototypeScreen({super.key});

  @override
  State<SupportPrototypeScreen> createState() => _SupportPrototypeScreenState();
}

class _SupportPrototypeScreenState extends State<SupportPrototypeScreen> {
  static const _names = [
    'A — Settings-style list',
    'B — Tip jar hero + grid',
    'C — Effort ladder',
  ];
  int _variant = 0;
  TipState _tipState = TipState.loaded;
  ProtoPlatform _platform = ProtoPlatform.ios;

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _onWayTap(SupportWay way) =>
      _snack('Would open: ${way.target(_platform)}');

  void _onTip(TipProduct tip) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thank you!'),
        content: Text(
          'Your ${tip.name.toLowerCase()} (${tip.price}) helps keep OpenNutriTracker free.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    setState(() => _tipState = TipState.tipped);
  }

  @override
  Widget build(BuildContext context) {
    final model = SupportProtoModel(
      platform: _platform,
      tipState: _tipState,
      onWayTap: _onWayTap,
      onTip: _onTip,
      onRetry: () => setState(() => _tipState = TipState.loaded),
    );
    final body = switch (_variant) {
      0 => SupportVariantA(model: model),
      1 => SupportVariantB(model: model),
      _ => SupportVariantC(model: model),
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Support OpenNutriTracker')),
      body: Stack(
        children: [
          Positioned.fill(child: body),
          if (!kReleaseMode)
            Positioned(
              left: 12,
              right: 12,
              bottom: 24,
              child: _switcher(context),
            ),
        ],
      ),
    );
  }

  Widget _switcher(BuildContext context) {
    final style = const TextStyle(color: Colors.white, fontSize: 13);
    Widget chip(String label, VoidCallback onTap) => InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          label,
          style: style.copyWith(decoration: TextDecoration.underline),
        ),
      ),
    );
    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      elevation: 8,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  color: Colors.white,
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () =>
                      setState(() => _variant = (_variant + 2) % 3),
                ),
                Expanded(
                  child: Text(
                    _names[_variant],
                    textAlign: TextAlign.center,
                    style: style.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  color: Colors.white,
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () =>
                      setState(() => _variant = (_variant + 1) % 3),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                chip(
                  'tips: ${_tipState.name}',
                  () => setState(
                    () => _tipState = TipState
                        .values[(_tipState.index + 1) % TipState.values.length],
                  ),
                ),
                chip(
                  'os: ${_platform.name}',
                  () => setState(
                    () => _platform = _platform == ProtoPlatform.ios
                        ? ProtoPlatform.android
                        : ProtoPlatform.ios,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
