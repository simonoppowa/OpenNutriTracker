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
///   while one is already running, joins the running probe instead.
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

  final _inFlight = <AiProvider, Future<AiEndpointProbe>>{};

  AiEndpointProbeRunner(this._credentials, this._prober);

  /// The probe running against [provider] right now, or null.
  Future<AiEndpointProbe>? current(AiProvider provider) => _inFlight[provider];

  /// Starts a probe against [provider], or joins the one already running.
  ///
  /// Completes with what is stored afterwards, so a caller can render the
  /// answer without a second read.
  Future<AiEndpointProbe> start(AiProvider provider, {String? localeCode}) {
    final running = _inFlight[provider];
    if (running != null) return running;
    final started = _run(provider, localeCode: localeCode);
    _inFlight[provider] = started;
    return started;
  }

  Future<AiEndpointProbe> _run(
    AiProvider provider, {
    String? localeCode,
  }) async {
    try {
      // The same read every real request goes through, which is what makes
      // this a probe of the configuration rather than of an argument. It
      // answers null while the feature is paused, and that is honoured: pause
      // means nothing is sent, and a probe is a request like any other.
      final selection = await _credentials.readSelection();
      if (selection == null || selection.provider != provider) {
        _log.info('Nothing to probe for ${provider.name}');
      } else {
        await _credentials.writeProbe(
          await _prober.probe(selection, localeCode: localeCode),
          provider: provider,
        );
      }
    } catch (e, stackTrace) {
      _log.severe('Probe run failed for ${provider.name}', e, stackTrace);
    } finally {
      _inFlight.remove(provider);
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
}
