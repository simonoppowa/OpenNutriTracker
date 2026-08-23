import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/probe_ai_endpoint_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/run_ai_endpoint_probe_usecase.dart';

class _MemoryStorage implements FlutterSecureStorage {
  final store = <String, String>{};

  /// Reads held open until the test releases them.
  ///
  /// The window this runner has to survive is not the 66 seconds of the probe
  /// — it is the few milliseconds around the reads that decide what to send,
  /// while the dialog that started it still has a live provider selector. A
  /// map that answers in a microtask closes that window before a test can
  /// reach it.
  final readGates = <String, Completer<void>>{};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    final gate = readGates[key];
    if (gate != null) await gate.future;
    return store[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      store.remove(key);
    } else {
      store[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => store.remove(key);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Stands in for the real prober, which needs a server on the other end.
///
/// `implements` rather than a subclass: the only members this collaborator
/// publishes are the three probe calls, and the fields behind them are a
/// client and an asset loader neither of which exists in a unit test.
class _FakeProber implements AiEndpointProber {
  AiEndpointProbe result;
  Object? throws;

  /// Held open so a probe can be observed mid-flight — the state the whole
  /// runner exists for, since a real one takes about 66 seconds.
  Completer<void>? gate;

  int calls = 0;
  AiSelection? lastSelection;
  String? lastLocale;

  _FakeProber(this.result);

  @override
  Future<AiEndpointProbe> probe(
    AiSelection selection, {
    String? localeCode,
  }) async {
    calls++;
    lastSelection = selection;
    lastLocale = localeCode;
    if (gate != null) await gate!.future;
    if (throws case final error?) throw error;
    return result;
  }

  @override
  Future<AiCapability> probeText(
    AiSelection selection, {
    String? localeCode,
  }) async => result.text;

  @override
  Future<AiCapability> probePhoto(
    AiSelection selection, {
    String? localeCode,
  }) async => result.photo;
}

void main() {
  const own = AiProvider.ownServer;
  const passedBoth = AiEndpointProbe(
    text: AiCapability.passed,
    photo: AiCapability.passed,
  );

  late _MemoryStorage backing;
  late AiCredentialStorage storage;
  late _FakeProber prober;
  late AiEndpointProbeRunner runner;

  Future<void> configure() async {
    await storage.setActiveProvider(own);
    await storage.writeOwnServerConfiguration(
      endpoint: 'http://192.168.1.5:11434',
      model: 'gemma3:4b',
      provider: own,
    );
  }

  setUp(() {
    backing = _MemoryStorage();
    storage = AiCredentialStorage(backing);
    prober = _FakeProber(passedBoth);
    runner = AiEndpointProbeRunner(storage, prober);
  });

  test('what it found is stored, not merely returned', () async {
    // The whole reason this class exists. #735 measured a full probe at about
    // 66 seconds, so whoever started it is gone; an answer that only ever
    // existed as a return value would be lost with them.
    await configure();

    await runner.start(own);

    final stored = await storage.readProbe(provider: own);
    expect(stored.text, AiCapability.passed);
    expect(stored.photo, AiCapability.passed);
  });

  test('the two capabilities are carried separately, end to end', () async {
    // #735: "text works, photos do not" is the common case for a small local
    // model, and it has to survive the trip through storage intact.
    await configure();
    prober.result = const AiEndpointProbe(
      text: AiCapability.passed,
      photo: AiCapability.failed,
    );

    final result = await runner.start(own);

    expect(result.text, AiCapability.passed);
    expect(result.photo, AiCapability.failed);
  });

  test('it answers with what is stored, not with what it found', () async {
    // Not the same thing, and the difference is the point of `writeProbe`'s
    // merge: an inconclusive verdict deliberately leaves a conclusive one
    // alone. A runner that returned the raw result would put "not checked
    // yet" in front of a user whose camera still works.
    await configure();
    await storage.writeProbe(passedBoth, provider: own);
    prober.result = AiEndpointProbe.unknown;

    final result = await runner.start(own);

    expect(result.text, AiCapability.passed);
    expect(result.photo, AiCapability.passed);
  });

  test('a second start joins the one already running', () async {
    // A local runtime serves one request at a time against one loaded model,
    // so a second probe would queue behind the first and double the wait for
    // both. Pressing OK twice, or reopening the dialog and pressing check
    // while a save's probe is still going, is ordinary.
    await configure();
    prober.gate = Completer<void>();

    final first = runner.start(own);
    final second = runner.start(own);
    prober.gate!.complete();
    await Future.wait([first, second]);

    expect(prober.calls, 1);
  });

  test('a probe in flight is visible, and stops being once it lands', () async {
    // What lets a dialog reopened over a running check say "checking" rather
    // than "not checked yet" — and, just as importantly, stop saying it.
    await configure();
    prober.gate = Completer<void>();

    final running = runner.start(own);
    expect(runner.current(own), isNotNull);

    prober.gate!.complete();
    await running;

    expect(runner.current(own), isNull);
  });

  test('a paused feature is not probed at all', () async {
    // Pause means nothing is sent, and a probe is a request like any other.
    // It goes through the same `readSelection` every real request does, so
    // this is the existing rule rather than a second copy of it.
    await configure();
    await storage.setEnabled(false);

    await runner.start(own);

    expect(prober.calls, 0);
  });

  test('an unconfigured provider leaves nothing behind', () async {
    // Nothing was asked, so nothing may be recorded. A `failed` written here
    // would hide a camera over a question that was never put to a server.
    await storage.setActiveProvider(own);

    final result = await runner.start(own);

    expect(prober.calls, 0);
    expect(result.text, AiCapability.unknown);
    expect(backing.store.keys.where((k) => k.startsWith('AiProbeTag')), isEmpty);
  });

  test('a probe that throws does not escape, and does not jam', () async {
    // A background courtesy must not take a settings screen down, and it must
    // not leave the runner believing a probe is still running — that would
    // make the dialog say "checking" forever and disable the retry with it.
    await configure();
    prober.throws = StateError('no model for ownServer');

    final result = await runner.start(own);

    expect(result.text, AiCapability.unknown);
    expect(runner.current(own), isNull);
  });

  test('a verdict about a configuration that has moved is dropped', () async {
    // #735: a pass is a fact about `(endpoint, model)`. `writeModel` clears
    // the stored verdict when the model changes — and a probe already in
    // flight would quietly fill it back in, certifying the new model with the
    // old one's evidence. Sixty-six seconds is a long time to hold that door
    // open: picking another model from the fetched list is two taps.
    await configure();
    prober.gate = Completer<void>();

    final running = runner.start(own);
    await pumpEventQueue();
    expect(prober.calls, 1, reason: 'the probe should be under way');

    await storage.writeModel('gemma3:12b', provider: own);
    prober.gate!.complete();
    final result = await running;

    expect(result.text, AiCapability.unknown);
    expect(
      backing.store.keys.where((k) => k.startsWith('AiProbeTag')),
      isEmpty,
      reason: 'the slot the model change cleared must stay cleared',
    );
  });

  test('a join whose configuration moved probes again instead', () async {
    // The other half of the same window. Saving starts a probe (#780), and
    // joining is what makes pressing OK twice free — but only while the
    // running probe is still testing what is stored. Otherwise the second
    // save is answered with the first save's verdict and the new
    // configuration is never checked at all.
    await configure();
    prober.gate = Completer<void>();

    final first = runner.start(own);
    await pumpEventQueue();
    await storage.writeModel('gemma3:12b', provider: own);
    final second = runner.start(own);

    prober.gate!.complete();
    await Future.wait([first, second]);

    expect(prober.calls, 2);
    expect(prober.lastSelection?.modelId, 'gemma3:12b');
    final stored = await storage.readProbe(provider: own);
    expect(stored.photo, AiCapability.passed);
  });

  test('a provider switch while it is starting does not cancel it', () async {
    // A check is a question about the provider it was started for, not about
    // whoever happens to be selected when it gets around to asking. The
    // dialog writes the active provider on the tap and keeps the radios live
    // across the configuration write that precedes the check, so a tap
    // landing in between used to make the check read a provider nobody had
    // asked it about, find nothing configured there, and quietly do nothing —
    // right after telling the user it had started.
    //
    // Held at the provider tag rather than gating the probe itself: reading
    // the active provider is the step that should no longer happen at all.
    await configure();
    backing.readGates['AiProviderTag'] = Completer<void>();

    final running = runner.start(own);
    await pumpEventQueue();
    await storage.setActiveProvider(AiProvider.anthropic);
    backing.readGates.remove('AiProviderTag')!.complete();
    await running;

    expect(prober.calls, 1);
    final stored = await storage.readProbe(provider: own);
    expect(stored.text, AiCapability.passed);
    expect(stored.photo, AiCapability.passed);
  });

  test('the language the user reads in reaches the request', () async {
    // The system prompt asks for food names in the user's language, and the
    // probe goes through the shipping interpreters — so the probe has to be
    // the same request the user's meals will be, locale included.
    await configure();

    await runner.start(own, localeCode: 'de');

    expect(prober.lastLocale, 'de');
    expect(prober.lastSelection?.endpoint, isNotNull);
    expect(prober.lastSelection?.modelId, 'gemma3:4b');
  });
}
