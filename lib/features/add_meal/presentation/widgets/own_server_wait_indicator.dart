import 'dart:async';

import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The loading state for a server the user runs: a wait that reads as
/// waiting rather than as a hang. #1148.
///
/// A hosted provider answers in seconds and keeps the bare spinner. This one
/// has a 120 s budget (`ownServerTimeout`), and #774 measured why: Ollama
/// unloads a model after five idle minutes, so for someone logging three
/// meals a day the *first* request is the ordinary case, and on an M4 Mac
/// mini that took 22–24 s before the server answered at all. A spinner alone
/// for that long — no movement, no words, no way out — is what a user reads
/// as broken, and #774's *transient* misdiagnosis used to send them off to
/// debug a network that was fine.
///
/// Three things, each answering one way the plain spinner failed:
///
/// * **The seconds count up**, so the screen is visibly alive.
/// * **After [hintAfter]**, a sentence says what is probably happening — the
///   model is loading, and that is normal. It is the point of the widget: the
///   user has no other way to know it. Not from the first second, because
///   a warm model answers in 8–17 s and a notice that fires on every request
///   becomes wallpaper.
/// * **Cancel**, from the first second. Waiting two minutes with no way out
///   is the part that reads as a hang, whatever else is on screen.
///
/// Counts ticks rather than reading the clock, so a widget test can drive it
/// with `pump(duration)` and so the threshold means the same thing in a test
/// as on a phone.
class OwnServerWaitIndicator extends StatefulWidget {
  /// How long before the model-loading sentence appears.
  ///
  /// Below the warm range #774 measured (8–17 s) would fire it on requests
  /// that are about to answer; well above the cold one (22–24 s) would show
  /// it only after the wait it explains was mostly over. Ten seconds is
  /// where a user who has not seen an answer starts wondering, which is
  /// exactly when the sentence is worth reading.
  static const hintAfter = Duration(seconds: 10);

  final VoidCallback onCancel;

  const OwnServerWaitIndicator({super.key, required this.onCancel});

  @override
  State<OwnServerWaitIndicator> createState() => _OwnServerWaitIndicatorState();
}

class _OwnServerWaitIndicatorState extends State<OwnServerWaitIndicator> {
  static const _tick = Duration(seconds: 1);

  Timer? _ticker;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(_tick, (_) {
      setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final showHint =
        _elapsedSeconds >= OwnServerWaitIndicator.hintAfter.inSeconds;

    return Padding(
      padding: const EdgeInsets.all(24),
      // Scrollable rather than clipped, as every message in this region is
      // (#777): it takes a tight height from the `Expanded` above, and the
      // hint is a full sentence that German at 2x will not fit in a fixed
      // box. The cancel button is the last child, so clipping would take
      // the one control this widget exists to offer.
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                s.bulkAddWaitElapsedLabel(_elapsedSeconds),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              if (showHint) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.memory_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    // Body copy, meant to wrap: no cap, for the reason #777
                    // settled — the words are the point.
                    Expanded(
                      child: Text(
                        s.bulkAddWaitModelLoadingLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Semantics(
                identifier: 'bulk-add-wait-cancel',
                child: TextButton(
                  onPressed: widget.onCancel,
                  child: Text(s.bulkAddWaitCancelLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
