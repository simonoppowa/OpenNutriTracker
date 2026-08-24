import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/probe_ai_endpoint_usecase.dart';

/// Runs a probe **behind** whatever started it, and leaves the answer where
/// the user can read it later.
///
/// The reason this exists rather than the settings dialog awaiting
/// [AiEndpointProber.probe] directly: #779 measured a full probe at about 66
/// seconds against a cold Ollama — 29s for the text call, 37s for the photo
/// one — and #735 settled that saving is never blocked on it. So the thing
/// that starts a probe is gone long before it finishes, and a `Future` owned
/// by a disposed `State` has nowhere to put its result.
///
/// It owns three facts a widget cannot:
///
/// - **The result is stored, not returned.** [start] writes through
///   [AiCredentialStorage.writeProbe] and hands back what is *now stored*,
///   which is not always what the probe found: an inconclusive verdict
///   deliberately leaves a conclusive one alone. A caller rendering the raw
///   result would show "not checked yet" over a pass that is still true.
/// - **One probe per provider at a time.** A local runtime serves one request
///   at a time, so a second probe would queue behind the first and double the
///   wait for both. Saving twice, or reopening the dialog and pressing check
///   while one is already running, joins the running probe instead — but only
///   while what it is testing is still what is stored (see [start]).
/// - **A probe in flight is observable.** [current] is what lets a dialog
///   reopened mid-probe say "checking" rather than "not checked yet", and
///   catch the result live if the user is still looking when it lands.
///
/// Nothing here throws. A probe is a background courtesy; a settings screen
/// that a keystore hiccup can take down would be a worse failure than the one
/// being reported.
class AiEndpointProbeRunner {
  static final _log = Logger('AiEndpointProbeRunner');

  final AiCredentialStorage _credentials;
  final AiEndpointProber _prober;

  final _inFlight = <AiProvider, _RunningProbe>{};

  AiEndpointProbeRunner(this._credentials, this._prober);

  /// The probe running against [provider] right now, or null.
  ///
  /// Briefly null in the middle of the restart [start] describes, between one
  /// probe finishing and its replacement registering — two keystore reads
  /// wide. A dialog opened inside that gap reads "not checked yet" and offers
  /// the retry, which is the state #735 already settled for a check that
  /// could not run, so it is worth no machinery to close.
  Future<AiEndpointProbe>? current(AiProvider provider) =>
      _inFlight[provider]?.result;

  /// Starts a probe against [provider], or joins the one already running.
  ///
  /// Completes with what is stored afterwards, so a caller can render the
  /// answer without a second read.
  ///
  /// **Joining is conditional**, because a running probe is a question about
  /// one `(endpoint, model)` and #735 made a pass a fact about exactly that
  /// pair. The ordinary way to get two of them in flight is not a race: the
  /// probe takes about 66 seconds, and picking a different model from the
  /// fetched list and pressing OK inside that window takes two taps. Joining
  /// unconditionally would answer the second save with the first save's
  /// verdict — a pass earned by one model, stored against another, which is
  /// how a camera would appear for a configuration nothing has ever
  /// successfully sent a photo to. So a join waits for the running probe and
  /// then asks whether it was still testing what is stored; if not, it starts
  /// a fresh one rather than returning an answer about a machine the user has
  /// moved off. Sequentially rather than at once, because the reason for
  /// deduplicating in the first place is a runtime that serves one request at
  /// a time.
  Future<AiEndpointProbe> start(AiProvider provider, {String? localeCode}) {
    final running = _inFlight[provider];
    if (running != null) {
      return _joinOrRepeat(provider, running, localeCode: localeCode);
    }
    final started = _RunningProbe();
    // `_run` runs as far as its first `await` and hands back a pending
    // future, so this whole block is one synchronous turn: the slot is filled
    // before anything can look for it. Deduplication has to work that way —
    // deciding it after a read of its own would let two saves both miss.
    started.result = _run(started, provider, localeCode: localeCode);
    _inFlight[provider] = started;
    return started.result;
  }

  Future<AiEndpointProbe> _joinOrRepeat(
    AiProvider provider,
    _RunningProbe running, {
    String? localeCode,
  }) async {
    final joined = await running.result;
    // `_run` clears its own slot before completing, so the restart below
    // starts into an empty one rather than joining what it just waited for.
    // Two unreadable answers compare equal and take the join, which is the
    // right way round: a keystore that will not talk should not be a reason
    // to keep starting probes.
    if (await _configurationOf(provider) == running.testing) return joined;
    _log.info('Configuration moved under a probe for ${provider.name}');
    return start(provider, localeCode: localeCode);
  }

  Future<AiEndpointProbe> _run(
    _RunningProbe running,
    AiProvider provider, {
    String? localeCode,
  }) async {
    try {
      // Read the configuration **once**, and take the identity from it.
      //
      // This used to ask `_configurationOf` first and `selectionFor` after,
      // which is two reads with a gap between them: a save landing in the gap
      // probed one machine and validated another. #813 made the selection
      // read atomic, and asking only it removes the gap as well as the
      // disagreement. `_configurationOf` is now reached only when there is
      // nothing to send, where the identity is a hint for a later join rather
      // than something a verdict is judged against.
      // Named rather than active: this is a probe of *this* provider's stored
      // configuration, not of whoever happens to be selected when it gets
      // around to asking. Reading the active selection instead put a window
      // between the dialog's configuration write and this read — small, a few
      // keystore round trips, but the radios are live across it and a tap
      // landing inside made a check the user had just been told had started
      // find another provider, conclude there was nothing to do, and stop. It
      // still answers null while the feature is paused: pause means nothing
      // is sent, and a probe is a request like any other.
      final selection = await _credentials.selectionFor(provider);
      if (selection == null) {
        running.testing = await _configurationOf(provider);
        _log.info('Nothing to probe for ${provider.name}');
      } else {
        // The identity of what is about to be sent, taken from the selection
        // itself. #800: validating against a separately-read snapshot threw
        // good verdicts away, and stored the new machine's verdict against
        // the old one when the configuration changed back before the probe
        // returned.
        final tested = (
          endpoint: selection.endpoint,
          modelId: selection.modelId,
        );
        // Kept in step so a caller joining mid-flight compares against what
        // is really being tested.
        running.testing = tested;
        final found = await _prober.probe(selection, localeCode: localeCode);
        // Compare and write in the store as one serialized operation. A check
        // here would leave a window where a configuration change clears the
        // slot before this stale verdict fills it back in.
        final stored = await _credentials.writeProbeIfConfigurationMatches(
          found,
          provider: provider,
          endpoint: tested.endpoint,
          modelId: tested.modelId,
        );
        if (!stored) {
          _log.info('Dropped a verdict about a configuration that has moved');
        }
      }
    } catch (e, stackTrace) {
      _log.severe('Probe run failed for ${provider.name}', e, stackTrace);
    } finally {
      if (identical(_inFlight[provider], running)) _inFlight.remove(provider);
    }
    // Read back rather than returned from above, so what a caller renders is
    // exactly what a caller reopening the dialog tomorrow would read.
    try {
      return await _credentials.readProbe(provider: provider);
    } catch (e, stackTrace) {
      _log.severe('Could not read back the probe', e, stackTrace);
      return AiEndpointProbe.unknown;
    }
  }

  /// What a verdict for [provider] would be a fact *about*.
  ///
  /// The pair #735 named, and the same pair `writeEndpoint` and `writeModel`
  /// clear a stored verdict on — so this asks the storage its own question
  /// rather than inventing a second notion of when a destination has changed.
  /// The key is deliberately not part of it: a wrong one produces `auth`,
  /// which is inconclusive and never becomes a verdict.
  ///
  /// Answers null if the keystore will not say. Callers treat that as "no
  /// answer" rather than as a configuration, so an unreadable store drops a
  /// verdict rather than storing one it cannot justify.
  Future<_ProbeConfiguration?> _configurationOf(AiProvider provider) async {
    try {
      return (
        endpoint: await _credentials.readEndpoint(provider: provider),
        modelId: await _credentials.readModel(provider: provider),
      );
    } catch (e, stackTrace) {
      _log.severe('Could not read the configuration', e, stackTrace);
      return null;
    }
  }
}

/// The `(endpoint, model)` a verdict belongs to. A record, so two of them
/// compare by value without anyone writing an `==`.
typedef _ProbeConfiguration = ({String? endpoint, String? modelId});

/// A probe and the configuration it is testing.
///
/// The two cannot be captured together at the point the probe starts: naming
/// the configuration takes a keystore read, and deduplication has to be
/// decided synchronously or two saves in the same turn both start one. So the
/// future goes into the map immediately and [testing] is filled in a moment
/// later, which is why it is nullable rather than final.
class _RunningProbe {
  late final Future<AiEndpointProbe> result;

  /// Null until the read lands, and null again if the store would not answer.
  _ProbeConfiguration? testing;
}
