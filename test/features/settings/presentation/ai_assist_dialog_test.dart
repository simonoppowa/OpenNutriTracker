import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/core/utils/ai_model_catalogue.dart';
import 'package:opennutritracker/core/utils/ai_model_list_api.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/probe_ai_endpoint_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/run_ai_endpoint_probe_usecase.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/ai_assist_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../helpers/test_l10n.dart';

class _MemoryStorage implements FlutterSecureStorage {
  final store = <String, String>{};

  /// Reads held open until the test releases them.
  ///
  /// The real store is a platform channel, so two reads issued in order are
  /// free to answer out of order — which is the whole of the race the dialog
  /// guards against. A map that answers in a microtask can never reproduce
  /// that on its own.
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
/// The dialog is given a **real** [AiEndpointProbeRunner] built around this,
/// not a fake runner: the thing worth asserting is that pressing OK does not
/// wait on a check, and a fake runner that returned instantly would make that
/// true by construction.
class _FakeProber implements AiEndpointProber {
  AiEndpointProbe result;

  /// Held open so a check can be observed mid-flight. A real one takes about
  /// 66 seconds, which is the whole reason the dialog has a running state.
  Completer<void>? gate;

  int calls = 0;

  _FakeProber(this.result);

  @override
  Future<AiEndpointProbe> probe(
    AiSelection selection, {
    String? localeCode,
  }) async {
    calls++;
    if (gate != null) await gate!.future;
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

class _Server {
  final requests = <Uri>[];
  final http.Response Function(Uri url) _respond;

  /// Answers held open, per host, until the test releases them.
  ///
  /// A machine on someone's LAN answers when it answers, and everything this
  /// dialog gets wrong about model lists happens in that window. A fixture
  /// that replies in a microtask closes it before a test can reach it.
  ///
  /// **Per host, so they can be released out of order.** Two requests that
  /// always land in the order they were sent let a guard that drops a stale
  /// answer pass for the wrong reason — the newest answer would have been
  /// written last regardless.
  final gates = <String, Completer<void>>{};

  _Server(this._respond);

  /// A different list per host, so one server's answer can be told apart
  /// from the answer of the server asked before it.
  factory _Server.perHost(Map<String, List<String>> byHost) => _Server(
    (url) => http.Response(
      jsonEncode({
        'object': 'list',
        'data': [
          for (final id in byHost[url.host] ?? const <String>[])
            {'id': id, 'object': 'model'},
        ],
      }),
      200,
    ),
  );

  /// Answers with a `/v1/models` body in the shape all four runtimes serve.
  factory _Server.listing(List<String> ids) => _Server(
    (_) => http.Response(
      jsonEncode({
        'object': 'list',
        'data': [for (final id in ids) {'id': id, 'object': 'model'}],
      }),
      200,
    ),
  );

  /// Nothing is listening — asleep, on another network, or a VPN that is off.
  factory _Server.unreachable() =>
      _Server((_) => throw const SocketException('connection refused'));

  late final AiModelListApi api = AiModelListApi(
    client: MockClient((request) async {
      requests.add(request.url);
      final held = gates[request.url.host];
      if (held != null) await held.future;
      return _respond(request.url);
    }),
  );
}

Widget _app(
  AiCredentialStorage storage, {
  Locale? locale,
  AiModelListApi? modelList,
  AiEndpointProbeRunner? probeRunner,
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: const [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: S.supportedLocales,
  home: Scaffold(
    body: AiAssistDialog(
      storage: storage,
      modelList: modelList,
      probeRunner: probeRunner,
    ),
  ),
);

void main() {
  late _MemoryStorage backing;
  late AiCredentialStorage storage;

  setUp(() {
    backing = _MemoryStorage();
    storage = AiCredentialStorage(backing);
  });

  testWidgets('states what leaves the device before a key is entered', (
    tester,
  ) async {
    // The disclosure is the point of this dialog: saving a key adds a
    // destination the README lists, and that should not be behind a link.
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    // The provider paragraph and the shared sentences are concatenated into
    // one Text, so this asserts on the substrings rather than on equality —
    // the split is an implementation detail, the words reaching the user
    // are not.
    expect(
      find.textContaining(l10nEn.aiAssistDisclosureAnthropic),
      findsOneWidget,
    );
    expect(
      find.textContaining(l10nEn.aiAssistDisclosureCommon),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('names the destination that is actually selected', (
    tester,
  ) async {
    // The whole reason the disclosure is split: with OpenRouter selected it
    // must state a broker, a forwarded identity and a retention carve-out,
    // none of which is true of the direct path.
    await storage.setActiveProvider(AiProvider.openrouter);
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(l10nEn.aiAssistDisclosureOpenRouter),
      findsOneWidget,
    );
    expect(
      find.textContaining(l10nEn.aiAssistDisclosureAnthropic),
      findsNothing,
    );
    // And the shared sentences survive the switch rather than being
    // duplicated into each variant.
    expect(
      find.textContaining(l10nEn.aiAssistDisclosureCommon),
      findsOneWidget,
    );
  });

  testWidgets('switching provider swaps the disclosure with it', (
    tester,
  ) async {
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OpenRouter'));
    await tester.pumpAndSettle();

    expect(await storage.activeProvider(), AiProvider.openrouter);
    expect(
      find.textContaining(l10nEn.aiAssistDisclosureOpenRouter),
      findsOneWidget,
    );
  });

  testWidgets('a slower earlier read cannot repaint over a later choice', (
    tester,
  ) async {
    // Copilot raised this on #788 against the probe completion, and it is the
    // same question for every await in this dialog — `_load` is where it
    // actually bites. One provider switch is four keystore reads, the keystore
    // is a platform channel, and two switches in quick succession are free to
    // answer out of order. The loser used to win: the dialog repainted itself
    // with the provider the user had already moved off, while storage said
    // otherwise, which is precisely the "the row and the store disagree about
    // who is being sent to" failure this feature keeps having to close.
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    // Hold OpenRouter's last read open, so its snapshot is still in flight
    // when the next choice lands on top of it.
    final held = Completer<void>();
    backing.readGates['AiProbeTag.openrouter'] = held;

    await tester.tap(find.text('OpenRouter'));
    await tester.pump();
    await tester.tap(find.text(l10nEn.aiAssistProviderOwnServerLabel));
    await tester.pumpAndSettle();

    expect(await storage.activeProvider(), AiProvider.ownServer);
    expect(
      find.bySemanticsIdentifier('ai-assist-endpoint-field'),
      findsOneWidget,
      reason: 'the later choice is the one on screen',
    );

    held.complete();
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsIdentifier('ai-assist-endpoint-field'),
      findsOneWidget,
      reason: 'the OpenRouter snapshot landed last and must not repaint',
    );
    expect(
      find.textContaining(l10nEn.aiAssistDisclosureOpenRouter),
      findsNothing,
      reason: 'naming a destination the user is not configured for is the '
          'one thing this dialog must never do',
    );
  });

  testWidgets('the dialog says the feature is experimental, and why', (
    tester,
  ) async {
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    // A bare word invites the reader to supply their own meaning, and the two
    // obvious readings — might break, might be wrong — lead to different
    // decisions about whether to pay for an API key. So the dialog states it.
    expect(find.text(l10nEn.aiAssistExperimentalNote), findsOneWidget);
  });

  testWidgets('the marker is not appended to the dialog title', (tester) async {
    // Not an oversight. At textScaler 2.0 on a 320px phone, a title of
    // "AI meal assistance · Experimental" squeezes the content area and
    // overflows the dialog by 48px — the bound the model-row test pins. The
    // badge lives on the tile that opens this, and the note states the
    // meaning, so the title does not need to carry it too.
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    final title = tester.widget<Text>(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(l10nEn.settingsAiAssistLabel),
      ),
    );
    expect(title.data, l10nEn.settingsAiAssistLabel);
  });

  testWidgets('experimental is about stability, not model accuracy', (
    tester,
  ) async {
    // The check-your-rows caution already exists, fires only when a model ran,
    // and #661 settled that it must not accumulate status text. So the note
    // here must not repeat it.
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    expect(
      l10nEn.aiAssistExperimentalNote,
      isNot(contains(l10nEn.bulkAddReadByModelLabel)),
    );
    expect(find.textContaining(l10nEn.bulkAddReadByModelLabel), findsNothing);
  });

  testWidgets('OpenAI is offered, and says what it does with content', (
    tester,
  ) async {
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OpenAI'));
    await tester.pumpAndSettle();

    expect(await storage.activeProvider(), AiProvider.openai);
    expect(
      find.textContaining(l10nEn.aiAssistDisclosureOpenAI),
      findsOneWidget,
    );
    // The retention sentence is the whole reason this paragraph differs from
    // Anthropic's, so it is worth asserting it survived rather than only
    // that some OpenAI text rendered.
    expect(find.textContaining('30 days'), findsOneWidget);
    expect(
      find.textContaining(l10nEn.aiAssistDisclosureAnthropic),
      findsNothing,
    );
    expect(
      find.textContaining(l10nEn.aiAssistDisclosureOpenRouter),
      findsNothing,
    );
  });

  testWidgets('the OpenAI alternative is not labelled cheaper', (tester) async {
    // #686 measured no price and no quality gap between luna and terra — only
    // that terra lists more items. Reusing the cheaper/weaker label here
    // would assert two things nobody measured, in nine languages.
    await storage.setActiveProvider(AiProvider.openai);
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    expect(find.textContaining(l10nEn.aiAssistModelMoreItemsLabel), findsOne);
    expect(find.textContaining(l10nEn.aiAssistModelCheaperLabel), findsNothing);
    expect(
      find.textContaining(l10nEn.aiAssistModelRecommendedLabel),
      findsOne,
      reason: 'the conservative reader still leads',
    );
  });

  testWidgets('the key field names the provider it belongs to', (tester) async {
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();
    expect(
      find.text(l10nEn.aiAssistKeyFieldLabel('Anthropic')),
      findsOneWidget,
    );

    await tester.tap(find.text('OpenRouter'));
    await tester.pumpAndSettle();
    expect(
      find.text(l10nEn.aiAssistKeyFieldLabel('OpenRouter')),
      findsOneWidget,
    );
  });

  testWidgets('a key saved for one provider is not offered for the other', (
    tester,
  ) async {
    await storage.writeApiKey('sk-ant', provider: AiProvider.anthropic);
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();
    expect(find.textContaining(l10nEn.aiAssistKeySavedLabel), findsOneWidget);

    await tester.tap(find.text('OpenRouter'));
    await tester.pumpAndSettle();

    // Quietly unavailable, not an error: a setting the user can change.
    expect(find.text(l10nEn.aiAssistNoKeyForProviderLabel), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(
      await storage.readApiKey(provider: AiProvider.anthropic),
      'sk-ant',
      reason: 'and the other key is untouched',
    );
  });

  testWidgets('offers a model choice only where one exists', (tester) async {
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    // The direct path pins one model. Rendering a list of one would imply a
    // choice that is not there.
    expect(
      find.textContaining(AiModelCatalogue.anthropic.single.id),
      findsOneWidget,
    );
    expect(find.byType(RadioListTile<String>), findsNothing);

    await tester.tap(find.text('OpenRouter'));
    await tester.pumpAndSettle();

    expect(
      find.byType(RadioListTile<String>),
      findsNWidgets(AiModelCatalogue.openrouter.length),
    );
  });

  testWidgets('the default model is the one measurement chose', (tester) async {
    await storage.setActiveProvider(AiProvider.openrouter);
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    final selected = tester
        .widgetList<RadioListTile<String>>(find.byType(RadioListTile<String>))
        // ignore: deprecated_member_use
        .where((tile) => tile.value == tile.groupValue)
        .single;
    expect(selected.value, 'anthropic/claude-sonnet-5');
  });

  testWidgets('choosing a model stores it against that provider', (
    tester,
  ) async {
    await storage.setActiveProvider(AiProvider.openrouter);
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    // The model section sits below the credential block now, so it can be
    // off-screen on a phone-sized viewport.
    await tester.ensureVisible(find.text('anthropic/claude-haiku-4.5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('anthropic/claude-haiku-4.5'));
    await tester.pumpAndSettle();

    expect(
      await storage.readModel(provider: AiProvider.openrouter),
      'anthropic/claude-haiku-4.5',
    );
    expect(
      await storage.readModel(provider: AiProvider.anthropic),
      isNull,
      reason: 'the other provider keeps its own model',
    );
  });

  testWidgets('names the vendor that will actually serve each row', (
    tester,
  ) async {
    // Pinned with fallbacks off, so this is guaranteed rather than likely.
    //
    // Said **per row**, which is new. It was said once for the group until
    // #726 put OpenAI-served entries on this list, and that grouped line was
    // only ever a deduplication of a fact that did not vary between rows. It
    // varies now, so one line would be a lie about half of them.
    await storage.setActiveProvider(AiProvider.openrouter);
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    final vendors = AiModelCatalogue.openrouter.map((m) => m.servedBy).toSet();
    expect(
      vendors,
      {'Anthropic', 'OpenAI'},
      reason: 'the mixed-vendor branch is what this test exists to cover',
    );

    for (final vendor in vendors) {
      final rows = AiModelCatalogue.openrouter
          .where((m) => m.servedBy == vendor)
          .length;
      expect(
        find.textContaining(l10nEn.aiAssistServedByLabel(vendor)),
        findsNWidgets(rows),
        reason: 'one per row it serves; a grouped line would show exactly one',
      );
    }
  });

  testWidgets('the broker disclosure covers the vendor behind the broker', (
    tester,
  ) async {
    // Every other disclosure assertion in this file compares the rendered
    // text against the ARB value, so it stays green whatever the ARB says.
    // This one asserts the *content*, because the fact is load-bearing and
    // was missing: until #726 every curated OpenRouter model was
    // Anthropic-served, so the broker path always reached the vendor with the
    // strongest retention promise, and the paragraph only ever described
    // OpenRouter's own handling. With OpenAI on the list a user could be told
    // less about the same company than the direct path tells them.
    expect(
      l10nEn.aiAssistDisclosureOpenRouter,
      contains('under its own policy'),
      reason: 'the serving vendor retains on its own terms, not OpenRouter\'s',
    );

    await storage.setActiveProvider(AiProvider.openrouter);
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('under its own policy'),
      findsOneWidget,
      reason: 'stated in the dialog, not only in the ARB',
    );
  });

  testWidgets('no OpenRouter row claims to be cheaper than it is', (
    tester,
  ) async {
    // The label was keyed on the *provider*, so every non-default row on a
    // list got the same string. That held while each list was two entries
    // differing the same way. On four it reached `openai/gpt-5.6-terra`,
    // which matches claude-sonnet-5 on input price and is dearer on output —
    // the row asserted something the price table contradicts. #726.
    await storage.setActiveProvider(AiProvider.openrouter);
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(l10nEn.aiAssistModelCheaperLabel),
      findsOne,
      reason: 'only claude-haiku-4.5, where #668 measured it',
    );
    expect(
      find.textContaining(l10nEn.aiAssistModelCheapestLabel),
      findsOne,
      reason: 'only gpt-5.6-luna, which is 5x below the next on both axes',
    );
    expect(
      find.textContaining(l10nEn.aiAssistModelMoreItemsLabel),
      findsOne,
      reason: 'only gpt-5.6-terra, where #686 measured 7 rows against 3',
    );
    expect(find.textContaining(l10nEn.aiAssistModelRecommendedLabel), findsOne);
  });

  group('a server the user runs', () {
    setUp(() => storage.setActiveProvider(AiProvider.ownServer));

    testWidgets('is offered, and is never called "local"', (tester) async {
      // #736: *local* is simultaneously what the ecosystem calls Ollama and
      // what a user reads as *on my phone* — the claim reserved for
      // on-device inference, which this app does not do. Someone who came
      // here for privacy and picked something labelled "Local AI" would have
      // been told the one thing that is not true, by the label alone.
      await tester.pumpWidget(_app(storage));
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.aiAssistProviderOwnServerLabel), findsOneWidget);
      expect(l10nEn.aiAssistProviderOwnServerLabel.toLowerCase(),
          isNot(contains('local')));
    });

    testWidgets('takes an address and a typed model name', (tester) async {
      // No curated list to pick from, so the model is typed. #757 adds the
      // fetch; this is what works until then.
      await tester.pumpWidget(_app(storage));
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier('ai-assist-endpoint-field'),
          findsOneWidget);
      expect(find.bySemanticsIdentifier('ai-assist-model-field'),
          findsOneWidget);
    });

    testWidgets('offers no curated model rows, and no served-by line', (
      tester,
    ) async {
      // #738: *Recommended* and the row notes are measured comparisons
      // between curated siblings, and nothing about a user's own models has
      // been measured by anyone. `servedBy` asserts a guarantee about a third
      // party, and there is not one.
      await tester.pumpWidget(_app(storage));
      await tester.pumpAndSettle();

      expect(find.byType(RadioListTile<String>), findsNothing);
      expect(find.textContaining(l10nEn.aiAssistModelRecommendedLabel),
          findsNothing);
      expect(find.textContaining('Served by'), findsNothing);
    });

    testWidgets('the disclosure names the host once one is typed', (
      tester,
    ) async {
      // #736: "sent to the server you configured" is not checkable at the
      // moment a user is agreeing to it.
      await tester.pumpWidget(_app(storage));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.bySemanticsIdentifier('ai-assist-endpoint-field'),
        'http://192.168.1.5:11434',
      );
      await tester.pumpAndSettle();

      // Asserted against the **disclosure**, not against any widget holding
      // that text. A first draft used `findsWidgets` and a mutation walked
      // through it: the endpoint field itself contains the host, so the test
      // passed while the disclosure named nothing at all.
      final disclosure = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .firstWhere((d) => d.contains(l10nEn.aiAssistDisclosureCommon));
      expect(disclosure, contains('192.168.1.5:11434'));
    });

    testWidgets('a password in the address never reaches the disclosure', (
      tester,
    ) async {
      // A reverse-proxied Ollama or vLLM behind basic auth is an ordinary
      // setup, and `Uri.authority` is `userInfo@host:port` — so the paragraph
      // the user is agreeing to printed their password back at them, in the
      // dialog whose whole premise is that a stored credential is not
      // readable off the screen.
      await tester.pumpWidget(_app(storage));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.bySemanticsIdentifier('ai-assist-endpoint-field'),
        'http://ollama:hunter2@192.168.1.5:11434',
      );
      await tester.pumpAndSettle();

      final disclosure = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .firstWhere((d) => d.contains(l10nEn.aiAssistDisclosureCommon));
      expect(disclosure, contains('192.168.1.5:11434'));
      expect(
        disclosure,
        isNot(contains('hunter2')),
        reason: 'the destination is nameable without the credential',
      );
    });

    testWidgets('the encryption clause follows the scheme, not a guess', (
      tester,
    ) async {
      await tester.pumpWidget(_app(storage));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.bySemanticsIdentifier('ai-assist-endpoint-field'),
        'http://192.168.1.5:11434',
      );
      await tester.pumpAndSettle();
      // Asserted against the string itself rather than the words "not
      // encrypted". The literal was a `findsNothing` that would have gone on
      // passing through any rewording — including the one that removed the
      // "stays on your own network" claim from this very sentence.
      expect(
        find.textContaining(
          l10nEn.aiAssistDisclosureOwnServerPlaintext('192.168.1.5:11434'),
        ),
        findsOneWidget,
        reason: 'the dialog is the only place a user learns this',
      );

      await tester.enterText(
        find.bySemanticsIdentifier('ai-assist-endpoint-field'),
        'https://ollama.example.com',
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          l10nEn.aiAssistDisclosureOwnServerSecure('ollama.example.com'),
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          l10nEn.aiAssistDisclosureOwnServerPlaintext('ollama.example.com'),
        ),
        findsNothing,
      );
    });

    testWidgets('saving stores the address and the model together', (
      tester,
    ) async {
      await tester.pumpWidget(_app(storage));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.bySemanticsIdentifier('ai-assist-endpoint-field'),
        'http://192.168.1.5:11434',
      );
      await tester.enterText(
        find.bySemanticsIdentifier('ai-assist-model-field'),
        'gemma3:4b',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nEn.dialogOKLabel));
      await tester.pumpAndSettle();

      expect(
        await storage.readEndpoint(provider: AiProvider.ownServer),
        'http://192.168.1.5:11434/v1/chat/completions',
        reason: 'a base address is completed to the route runtimes answer on',
      );
      expect(await storage.readModel(provider: AiProvider.ownServer),
          'gemma3:4b');
      expect(
        (await storage.readSummary()).configured,
        isTrue,
        reason: 'no key was entered, and none is needed',
      );
    });

    testWidgets('an address that is not a URL is refused, and says so', (
      tester,
    ) async {
      // `192.168.1.5:11434` is the form Ollama's own documentation shows, so
      // it is the likeliest thing to be typed here. It was stored happily,
      // turned the feature on, and then threw a FormatException inside the
      // request builder — into the catch-all that turns anything unexpected
      // into "the parser answered". The row said On and nothing ever ran.
      await tester.pumpWidget(_app(storage));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.bySemanticsIdentifier('ai-assist-endpoint-field'),
        '192.168.1.5:11434',
      );
      await tester.enterText(
        find.bySemanticsIdentifier('ai-assist-model-field'),
        'gemma3:4b',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nEn.dialogOKLabel));
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.aiAssistEndpointInvalidLabel), findsOneWidget);
      expect(await storage.readEndpoint(provider: AiProvider.ownServer), isNull);
      expect(
        find.byType(AiAssistDialog),
        findsOneWidget,
        reason: 'a refused save must not close the dialog',
      );
    });

    testWidgets('an address with no model is refused, and says so', (
      tester,
    ) async {
      // #738 made the model part of what "configured" means here, and nothing
      // enforced it: the address alone flipped the flag, and the request
      // builder then had no model to name and threw — swallowed the same way.
      await tester.pumpWidget(_app(storage));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.bySemanticsIdentifier('ai-assist-endpoint-field'),
        'http://192.168.1.5:11434',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nEn.dialogOKLabel));
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.aiAssistModelRequiredLabel), findsOneWidget);
      expect(await storage.readEndpoint(provider: AiProvider.ownServer), isNull);
      expect(
        await storage.isEnabled(),
        isFalse,
        reason: 'nothing was stored, so nothing may have turned it on',
      );
    });

    testWidgets('a refusal clears as soon as the field is edited', (
      tester,
    ) async {
      await tester.pumpWidget(_app(storage));
      await tester.pumpAndSettle();

      // A model with nowhere to send it is still a refusal, and it lands on
      // the field that is missing rather than the one that is filled in.
      await tester.enterText(
        find.bySemanticsIdentifier('ai-assist-model-field'),
        'gemma3:4b',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nEn.dialogOKLabel));
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.aiAssistEndpointInvalidLabel), findsOneWidget);

      await tester.enterText(
        find.bySemanticsIdentifier('ai-assist-endpoint-field'),
        'h',
      );
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.aiAssistEndpointInvalidLabel), findsNothing);
    });

    testWidgets('an untouched dialog closes rather than refusing', (
      tester,
    ) async {
      // Typing nothing is not an error — it is the same "not setting this up
      // right now" that an empty key field means for the hosted three, and
      // erroring on it would make OK a trap for anyone who opened the dialog
      // to look.
      await tester.pumpWidget(_app(storage));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10nEn.dialogOKLabel));
      await tester.pumpAndSettle();

      expect(find.byType(AiAssistDialog), findsNothing);
      expect(find.text(l10nEn.aiAssistEndpointInvalidLabel), findsNothing);
    });

    testWidgets('clearing a configured address is refused, not ignored', (
      tester,
    ) async {
      // The fields are editable and prefilled, so emptying them is an obvious
      // way to try to get rid of a server. It fell through the save branch
      // entirely: nothing written, dialog closed, and the row still naming
      // the address the user believed they had just deleted.
      await storage.writeOwnServerConfiguration(
        endpoint: 'http://192.168.1.5:11434',
        model: 'gemma3:4b',
      );
      await tester.pumpWidget(_app(storage));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.bySemanticsIdentifier('ai-assist-endpoint-field'),
        '',
      );
      await tester.enterText(
        find.bySemanticsIdentifier('ai-assist-model-field'),
        '',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nEn.dialogOKLabel));
      await tester.pumpAndSettle();

      expect(find.byType(AiAssistDialog), findsOneWidget);
      expect(find.text(l10nEn.aiAssistEndpointInvalidLabel), findsOneWidget);
      expect(
        await storage.readEndpoint(provider: AiProvider.ownServer),
        'http://192.168.1.5:11434/v1/chat/completions',
        reason: 'refusing must not delete it either — Remove does that',
      );
    });

    testWidgets('the address stays editable after it is saved', (
      tester,
    ) async {
      // The dialog rendered the address and model fields unconditionally but
      // hung OK off "has a credential", which for this provider is true as
      // soon as an address exists. Reopening therefore showed two editable
      // fields, a disclosure that followed every keystroke, and nothing to
      // commit any of it — the only exit was Remove, which discards the
      // address too. Changing the machine you run Ollama on should not mean
      // tearing the whole setting down.
      await storage.writeEndpoint(
        'http://192.168.1.5:11434',
        provider: AiProvider.ownServer,
      );
      await storage.writeModel('gemma3:4b', provider: AiProvider.ownServer);
      await tester.pumpWidget(_app(storage));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.bySemanticsIdentifier('ai-assist-endpoint-field'),
        'http://192.168.1.9:11434',
      );
      await tester.enterText(
        find.bySemanticsIdentifier('ai-assist-model-field'),
        'qwen3:8b',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nEn.dialogOKLabel));
      await tester.pumpAndSettle();

      expect(await storage.readEndpoint(provider: AiProvider.ownServer),
          'http://192.168.1.9:11434/v1/chat/completions');
      expect(
        await storage.readModel(provider: AiProvider.ownServer),
        'qwen3:8b',
        reason: 'a changed address forgets the model, so order is load-bearing',
      );
    });

    testWidgets('the address stays editable once a key is stored too', (
      tester,
    ) async {
      // The case the OK gate is really for, and the one a first version of
      // the test above missed: with no key stored, splitting "has a key" from
      // "is configured" already brings OK back, so the mutation walked
      // through. It is a server the user runs that *also* holds an optional
      // key — a reverse-proxied one — where the credential row appears, OK
      // disappeared with it, and the address underneath was frozen.
      await storage.writeEndpoint(
        'http://192.168.1.5:11434',
        provider: AiProvider.ownServer,
      );
      await storage.writeModel('gemma3:4b', provider: AiProvider.ownServer);
      await storage.writeApiKey('sk-proxy', provider: AiProvider.ownServer);
      await tester.pumpWidget(_app(storage));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(l10nEn.aiAssistKeySavedLabel),
        findsOneWidget,
        reason: 'this one really does hold a key',
      );

      await tester.enterText(
        find.bySemanticsIdentifier('ai-assist-endpoint-field'),
        'http://192.168.1.9:11434',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nEn.dialogOKLabel));
      await tester.pumpAndSettle();

      expect(await storage.readEndpoint(provider: AiProvider.ownServer),
          'http://192.168.1.9:11434/v1/chat/completions');
    });

    testWidgets('no key stored is not reported as a key saved', (
      tester,
    ) async {
      // "Key saved ••••••••••••" over a slot holding nothing, in the one
      // dialog whose whole job is to be checkable on sight. `configured` and
      // `has a key` are the same fact for the hosted three and different for
      // this one.
      await storage.writeEndpoint(
        'http://192.168.1.5:11434',
        provider: AiProvider.ownServer,
      );
      await tester.pumpWidget(_app(storage));
      await tester.pumpAndSettle();

      expect(await storage.readApiKey(provider: AiProvider.ownServer), isNull);
      expect(find.textContaining(l10nEn.aiAssistKeySavedLabel), findsNothing);
      // Still offered, because the key here is optional rather than absent —
      // a reverse-proxied server may want one after the address is working.
      expect(
        find.bySemanticsIdentifier('ai-assist-key-field'),
        findsOneWidget,
      );
    });

    testWidgets('OK on an unchanged address does not un-pause it', (
      tester,
    ) async {
      // The switch and OK are on screen together for this provider, and
      // `writeEndpoint` reads an address as the user asking for the feature —
      // right for a new one, wrong for the one already stored. Pausing and
      // then confirming the dialog must not undo the pause.
      await storage.writeEndpoint(
        'http://192.168.1.5:11434',
        provider: AiProvider.ownServer,
      );
      await storage.writeModel('gemma3:4b', provider: AiProvider.ownServer);
      await tester.pumpWidget(_app(storage));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(await storage.isEnabled(), isFalse);

      await tester.tap(find.text(l10nEn.dialogOKLabel));
      await tester.pumpAndSettle();

      expect(await storage.isEnabled(), isFalse);
    });

    testWidgets('pausing is offered with no key stored', (tester) async {
      // The switch and Remove follow "is this usable", which for this
      // provider is an address and a model rather than a key. They used to
      // ride on the same flag as the masked key row.
      await storage.writeEndpoint(
        'http://192.168.1.5:11434',
        provider: AiProvider.ownServer,
      );
      await storage.writeModel('gemma3:4b', provider: AiProvider.ownServer);
      await tester.pumpWidget(_app(storage));
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier('ai-assist-enabled'), findsOneWidget);
      expect(
        find.bySemanticsIdentifier('ai-assist-remove-key'),
        findsOneWidget,
      );
    });

    testWidgets('survives 2x German on a narrow phone', (tester) async {
      // Where this dialog's title lost its Experimental badge for
      // overflowing by 48px. A user-supplied hostname is less bounded than
      // anything else it renders, so this is measured rather than assumed.
      //
      // The 2x was in the name and nowhere else: this set the viewport and
      // stopped, so it measured a narrow phone at the default font and said
      // "2x German" about it. The scaler has to be wrapped round the widget
      // the way the two tests below do it — `tester.view` carries no text
      // scale.
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await storage.writeEndpoint(
        'http://very-long-server-name.home.arpa:11434',
        provider: AiProvider.ownServer,
      );
      await storage.writeModel('gemma3:4b', provider: AiProvider.ownServer);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: _app(storage, locale: const Locale('de')),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    group('the model list', () {
      /// Puts the address on screen without going near the store, so a test
      /// starts where a user who has just typed one does.
      Future<void> typeEndpoint(
        WidgetTester tester,
        String endpoint,
      ) async {
        await tester.enterText(
          find.bySemanticsIdentifier('ai-assist-endpoint-field'),
          endpoint,
        );
        await tester.pumpAndSettle();
      }

      /// Commits an address **without letting the clock run**.
      ///
      /// `pumpAndSettle` advances the fake clock until nothing is scheduled,
      /// and `AiModelListApi` carries a 15-second timeout — so a request held
      /// open by [_Server.gate] times out instead of staying in flight, and
      /// the window these cases are about never exists. Two sequential
      /// fetches look exactly like the bug being tested for, which is how the
      /// first version of this passed against the unfixed code.
      Future<void> commitEndpoint(WidgetTester tester, String endpoint) async {
        await tester.enterText(
          find.bySemanticsIdentifier('ai-assist-endpoint-field'),
          endpoint,
        );
        await tester.pump();
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
      }

      Future<void> pressLoad(WidgetTester tester) async {
        final button = find.bySemanticsIdentifier('ai-assist-load-models');
        // The dialog is taller than a phone by design, so the control may
        // well be past the fold — which is a scroll, not a failure.
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button);
        await tester.pumpAndSettle();
      }

      /// Every sentence the model list can produce for [host].
      ///
      /// Named all at once so that "this was not reported as an error" is an
      /// assertion with teeth rather than one that happens to check the
      /// message nobody was going to show anyway.
      List<String> messagesFor(String host) => [
        l10nEn.aiAssistModelsUnreachableLabel(host),
        l10nEn.aiAssistModelsEmptyLabel(host),
        l10nEn.aiAssistModelsRejectedLabel(host),
        l10nEn.aiAssistModelsInsecureLabel,
      ];

      testWidgets('opening the dialog asks the server nothing', (tester) async {
        // The promise the README is built on is about what leaves the device
        // **and when**. For the three hosted providers, opening AI settings
        // sends nothing anywhere; this provider's address is a machine on the
        // user's own network, reached from a screen they may have opened to
        // change the theme. #738: never on open.
        final server = _Server.listing(['gemma3:4b']);
        await storage.writeOwnServerConfiguration(
          endpoint: 'http://192.168.1.5:11434',
          model: 'gemma3:4b',
          provider: AiProvider.ownServer,
        );

        await tester.pumpWidget(_app(storage, modelList: server.api));
        await tester.pumpAndSettle();

        expect(
          server.requests,
          isEmpty,
          reason: 'a configured server must not be contacted by a dialog '
              'simply being opened',
        );
      });

      testWidgets('switching to this provider asks the server nothing', (
        tester,
      ) async {
        // The other silent moment. A user comparing providers should be able
        // to read this row's disclosure without a request leaving for the
        // address stored behind it.
        final server = _Server.listing(['gemma3:4b']);
        await storage.writeOwnServerConfiguration(
          endpoint: 'http://192.168.1.5:11434',
          model: 'gemma3:4b',
          provider: AiProvider.ownServer,
        );
        await storage.setActiveProvider(AiProvider.anthropic);

        await tester.pumpWidget(_app(storage, modelList: server.api));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10nEn.aiAssistProviderOwnServerLabel));
        await tester.pumpAndSettle();

        expect(server.requests, isEmpty);
      });

      testWidgets('Load models asks the address that is on screen', (
        tester,
      ) async {
        final server = _Server.listing(['qwen3:8b', 'gemma3:4b']);
        await tester.pumpWidget(_app(storage, modelList: server.api));
        await tester.pumpAndSettle();

        await typeEndpoint(tester, 'http://192.168.1.5:11434');
        await pressLoad(tester);

        expect(server.requests, [
          Uri.parse('http://192.168.1.5:11434/v1/models'),
        ]);
        expect(
          find.bySemanticsIdentifier('ai-assist-model-picker'),
          findsOneWidget,
        );
      });

      testWidgets('picking a fetched model stores it', (tester) async {
        final server = _Server.listing(['qwen3:8b', 'gemma3:4b']);
        await tester.pumpWidget(_app(storage, modelList: server.api));
        await tester.pumpAndSettle();

        await typeEndpoint(tester, 'http://192.168.1.5:11434');
        await pressLoad(tester);

        await tester.ensureVisible(find.byType(DropdownButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DropdownButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('qwen3:8b').last);
        await tester.pumpAndSettle();

        // OK is the one commit point for this provider: the address is typed
        // text and a model belongs to an address, so writing one against an
        // address that is not stored yet would be wiped by the endpoint write
        // that followed it.
        await tester.tap(find.bySemanticsIdentifier('ai-assist-save-key'));
        await tester.pumpAndSettle();

        expect(
          await storage.readModel(provider: AiProvider.ownServer),
          'qwen3:8b',
        );
        expect(
          await storage.readEndpoint(provider: AiProvider.ownServer),
          'http://192.168.1.5:11434/v1/chat/completions',
        );
      });

      testWidgets('an unreachable server leaves the model typeable', (
        tester,
      ) async {
        // **The fallback, and the reason it exists.** Settings get opened
        // while the server is asleep, on another network, or behind a VPN
        // that is off. A dialog that could only offer what it can reach would
        // be unconfigurable exactly when someone is setting it up ahead of
        // time.
        final server = _Server.unreachable();
        await tester.pumpWidget(_app(storage, modelList: server.api));
        await tester.pumpAndSettle();

        await typeEndpoint(tester, 'http://192.168.1.5:11434');
        await pressLoad(tester);

        expect(
          find.bySemanticsIdentifier('ai-assist-model-field'),
          findsOneWidget,
          reason: 'the field a user can type into must survive the fetch '
              'failing, or the feature is unconfigurable off the network',
        );

        await tester.enterText(
          find.bySemanticsIdentifier('ai-assist-model-field'),
          'gemma3:4b',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsIdentifier('ai-assist-save-key'));
        await tester.pumpAndSettle();

        expect(
          await storage.readModel(provider: AiProvider.ownServer),
          'gemma3:4b',
        );
      });

      testWidgets('a server that cannot be reached says so, and an empty one '
          'says something else', (tester) async {
        // Both produce a blank picker and they want opposite fixes: wake the
        // machine, or pull a model. One message covering both would send half
        // its readers to the wrong place.
        final unreachable = _Server.unreachable();
        await tester.pumpWidget(_app(storage, modelList: unreachable.api));
        await tester.pumpAndSettle();
        await typeEndpoint(tester, 'http://192.168.1.5:11434');
        await pressLoad(tester);

        expect(
          find.text(
            l10nEn.aiAssistModelsUnreachableLabel('192.168.1.5:11434'),
          ),
          findsOneWidget,
        );
        expect(
          find.text(l10nEn.aiAssistModelsEmptyLabel('192.168.1.5:11434')),
          findsNothing,
        );

        final empty = _Server.listing([]);
        await tester.pumpWidget(_app(storage, modelList: empty.api));
        await tester.pumpAndSettle();
        await typeEndpoint(tester, 'http://192.168.1.5:11434');
        await pressLoad(tester);

        expect(
          find.text(l10nEn.aiAssistModelsEmptyLabel('192.168.1.5:11434')),
          findsOneWidget,
        );
        expect(
          find.text(
            l10nEn.aiAssistModelsUnreachableLabel('192.168.1.5:11434'),
          ),
          findsNothing,
        );
      });

      testWidgets('one model is an ordinary choice, not an error', (
        tester,
      ) async {
        // llama.cpp serves exactly the one file it was started with. If a
        // single-element list read as a failure, the runtime with the
        // smallest footprint would be the one this dialog cannot configure.
        final server = _Server.listing(['Meta-Llama-3.1-8B-Q4_K_M']);
        await tester.pumpWidget(_app(storage, modelList: server.api));
        await tester.pumpAndSettle();

        await typeEndpoint(tester, 'http://192.168.1.5:8080');
        await pressLoad(tester);

        expect(
          find.bySemanticsIdentifier('ai-assist-model-picker'),
          findsOneWidget,
        );
        for (final message in messagesFor('192.168.1.5:8080')) {
          expect(find.text(message), findsNothing);
        }
      });

      testWidgets('the list says what exists, never what works', (
        tester,
      ) async {
        // `/v1/models` reports an `id` and little else, and none of the four
        // runtimes flags vision or tool support there. Nothing measured has
        // ever been said about a model somebody pulled, so no row may carry
        // *Recommended*, a comparison note, or a serving vendor. #738.
        final server = _Server.listing(['qwen3:8b', 'gemma3:4b']);
        await tester.pumpWidget(_app(storage, modelList: server.api));
        await tester.pumpAndSettle();

        await typeEndpoint(tester, 'http://192.168.1.5:11434');
        await pressLoad(tester);

        expect(
          find.textContaining(l10nEn.aiAssistModelRecommendedLabel),
          findsNothing,
        );
        expect(find.textContaining('Served by'), findsNothing);
        expect(
          find.textContaining(l10nEn.aiAssistModelCheaperLabel),
          findsNothing,
        );
      });

      testWidgets('changing the address fetches, and drops the model that '
          'belonged to the old one', (tester) async {
        // #755 clears the stored model whenever the address changes, because
        // `gemma3:4b` is a claim about one machine and says nothing about the
        // next. This is that rule where the user can see it happen — someone
        // alternating between a laptop and a desktop re-picks every time.
        final server = _Server.listing(['qwen3:8b']);
        await storage.writeOwnServerConfiguration(
          endpoint: 'http://192.168.1.5:11434',
          model: 'gemma3:4b',
          provider: AiProvider.ownServer,
        );
        await tester.pumpWidget(_app(storage, modelList: server.api));
        await tester.pumpAndSettle();

        expect(server.requests, isEmpty, reason: 'nothing on open');

        await typeEndpoint(tester, 'http://192.168.1.9:11434');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(server.requests, [
          Uri.parse('http://192.168.1.9:11434/v1/models'),
        ]);
        expect(
          tester
              .widget<TextField>(
                find.descendant(
                  of: find.bySemanticsIdentifier('ai-assist-model-field'),
                  matching: find.byType(TextField),
                ),
              )
              .controller
              ?.text,
          isEmpty,
          reason: 'the model belonged to the address that just changed',
        );
      });

      testWidgets('a second address committed while the first is still out '
          'is asked too', (tester) async {
        // #796. The one-request-per-act rule was read as "one at a time", so
        // committing a second address while the first was still out cleared
        // the model field and then sent nothing. The user is left looking at
        // an address nothing was ever asked about.
        final server = _Server.perHost({
          '192.168.1.9': ['qwen3:8b'],
          '192.168.1.7': ['llama3.2:3b'],
        });
        server.gates['192.168.1.9'] = Completer<void>();
        server.gates['192.168.1.7'] = Completer<void>();
        await storage.writeOwnServerConfiguration(
          endpoint: 'http://192.168.1.5:11434',
          model: 'gemma3:4b',
          provider: AiProvider.ownServer,
        );
        await tester.pumpWidget(_app(storage, modelList: server.api));
        await tester.pumpAndSettle();

        await commitEndpoint(tester, 'http://192.168.1.9:11434');
        await commitEndpoint(tester, 'http://192.168.1.7:11434');

        expect(server.requests, [
          Uri.parse('http://192.168.1.9:11434/v1/models'),
          Uri.parse('http://192.168.1.7:11434/v1/models'),
        ]);

        for (final gate in server.gates.values) {
          gate.complete();
        }
        await tester.pumpAndSettle();
      });

      testWidgets('the first server\'s list is not shown under the second '
          'server\'s address', (tester) async {
        // The visible half of the same bug, and the one that costs something:
        // `_pickModel` writes the chosen id into the model field, so a list
        // belonging to another machine is a model that does not exist on the
        // one being configured — stored, and left for the setup check to fail
        // on for a reason the dialog has already said is fine.
        final server = _Server.perHost({
          '192.168.1.9': ['qwen3:8b'],
          '192.168.1.7': ['llama3.2:3b'],
        });
        server.gates['192.168.1.9'] = Completer<void>();
        server.gates['192.168.1.7'] = Completer<void>();
        await storage.writeOwnServerConfiguration(
          endpoint: 'http://192.168.1.5:11434',
          model: 'gemma3:4b',
          provider: AiProvider.ownServer,
        );
        await tester.pumpWidget(_app(storage, modelList: server.api));
        await tester.pumpAndSettle();

        await commitEndpoint(tester, 'http://192.168.1.9:11434');
        await commitEndpoint(tester, 'http://192.168.1.7:11434');

        // **The newer answer first, then the older one.** Released in the
        // order they were sent, the right list would be written last by
        // accident and a missing guard would pass.
        server.gates['192.168.1.7']!.complete();
        await tester.pump();
        await tester.pump();
        server.gates['192.168.1.9']!.complete();
        await tester.pumpAndSettle();

        // The picker is closed, so it renders its hint rather than its items
        // — `find.text` on an id would pass whatever the list held. Read the
        // items off the widget instead.
        final picker = tester.widget<DropdownButton<String>>(
          find.descendant(
            of: find.bySemanticsIdentifier('ai-assist-model-picker'),
            matching: find.byType(DropdownButton<String>),
          ),
        );
        expect(
          picker.items?.map((item) => item.value),
          ['llama3.2:3b'],
          reason: 'the list on screen must belong to the address on screen',
        );
      });

      testWidgets('a list that lands after a provider switch changes '
          'nothing', (tester) async {
        // Every other await in this dialog drops a write that no longer
        // belongs (#788); this one arrived with #757 and did not. Contained
        // today only because the picker renders for this provider alone —
        // which is a fact about the current layout, not about the invariant.
        final server = _Server.perHost({
          '192.168.1.9': ['qwen3:8b'],
        });
        server.gates['192.168.1.9'] = Completer<void>();
        await storage.writeOwnServerConfiguration(
          endpoint: 'http://192.168.1.5:11434',
          model: 'gemma3:4b',
          provider: AiProvider.ownServer,
        );
        await tester.pumpWidget(_app(storage, modelList: server.api));
        await tester.pumpAndSettle();

        await commitEndpoint(tester, 'http://192.168.1.9:11434');

        // **Away and back before the answer lands**, which is the case a
        // provider check alone cannot see: by the time this request returns,
        // the provider it was started for is selected again. What makes it
        // stale is the reload in between, not who is on screen.
        await tester.tap(find.text('Anthropic'));
        await tester.pump();
        await tester.pump();
        await tester.tap(find.text(l10nEn.aiAssistProviderOwnServerLabel));
        await tester.pump();
        await tester.pump();

        server.gates['192.168.1.9']!.complete();
        await tester.pumpAndSettle();

        // No picker at all rather than an empty one: `_load` clears the list
        // on a switch, and nothing may put it back.
        expect(
          find.bySemanticsIdentifier('ai-assist-model-picker'),
          findsNothing,
        );
        final button = find.bySemanticsIdentifier('ai-assist-load-models');
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextButton>(
            find.descendant(of: button, matching: find.byType(TextButton)),
          ).onPressed,
          isNotNull,
          reason: 'a request nobody wants any more must not disable the '
              'button for the rest of the dialog',
        );
      });

      testWidgets('returning to a configured server and leaving the address '
          'alone asks nothing', (tester) async {
        // The other half of the same rule. Focus crossing the field is not a
        // URL change, or every glance at this dialog would be a request.
        final server = _Server.listing(['gemma3:4b']);
        await storage.writeOwnServerConfiguration(
          endpoint: 'http://192.168.1.5:11434',
          model: 'gemma3:4b',
          provider: AiProvider.ownServer,
        );
        await tester.pumpWidget(_app(storage, modelList: server.api));
        await tester.pumpAndSettle();

        await tester.showKeyboard(
          find.bySemanticsIdentifier('ai-assist-endpoint-field'),
        );
        await tester.pumpAndSettle();
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(server.requests, isEmpty);
      });

      testWidgets('Cancel asks nothing, even with a half-changed address in '
          'the field', (tester) async {
        // Leaving is not an explicit ask. Cancel takes focus off the address
        // field, and a focus-loss fetch fires on the way out — a request the
        // user never asked for, at the one moment they cannot see the answer,
        // to a machine on their own network. #738 allows exactly two moments
        // and this is neither.
        final server = _Server.listing(['gemma3:4b']);
        await storage.writeOwnServerConfiguration(
          endpoint: 'http://192.168.1.5:11434',
          model: 'gemma3:4b',
          provider: AiProvider.ownServer,
        );
        await tester.pumpWidget(_app(storage, modelList: server.api));
        await tester.pumpAndSettle();

        // Changed, so the only thing standing between this and a request is
        // the dialog knowing it is closing.
        await typeEndpoint(tester, 'http://192.168.1.9:11434');
        await tester.tap(find.text(l10nEn.dialogCancelLabel));
        await tester.pumpAndSettle();

        expect(
          server.requests,
          isEmpty,
          reason: 'a dialog being dismissed must not contact the address on '
              'its way out',
        );
      });

      testWidgets('moving on from a changed address fetches, without pressing '
          'anything', (tester) async {
        // The positive half of the two exit tests above. They prove the fetch
        // is *suppressed* while the route is going away; without this, they
        // would all still pass if the trigger were deleted outright and no
        // URL change ever fetched again.
        //
        // Focus moving to the model field, which is where someone goes next.
        final server = _Server.listing(['gemma3:4b']);
        await storage.writeOwnServerConfiguration(
          endpoint: 'http://192.168.1.5:11434',
          model: 'gemma3:4b',
          provider: AiProvider.ownServer,
        );
        await tester.pumpWidget(_app(storage, modelList: server.api));
        await tester.pumpAndSettle();

        await typeEndpoint(tester, 'http://192.168.1.9:11434');
        await tester.showKeyboard(
          find.bySemanticsIdentifier('ai-assist-model-field'),
        );
        await tester.pumpAndSettle();

        expect(server.requests, [
          Uri.parse('http://192.168.1.9:11434/v1/models'),
        ]);
      });

      testWidgets('moving an already-configured server to a new address saves '
          'both fields', (tester) async {
        // The third exit, and the one where suppressing the fetch has to not
        // break anything: OK must still commit what is on screen. If leaving
        // the address field cleared the model on the way to the button, this
        // would refuse with "name the model" over a name the user just typed.
        final server = _Server.listing(['gemma3:4b']);
        await storage.writeOwnServerConfiguration(
          endpoint: 'http://192.168.1.5:11434',
          model: 'gemma3:4b',
          provider: AiProvider.ownServer,
        );
        await tester.pumpWidget(_app(storage, modelList: server.api));
        await tester.pumpAndSettle();

        await typeEndpoint(tester, 'http://192.168.1.9:11434');
        await tester.enterText(
          find.bySemanticsIdentifier('ai-assist-model-field'),
          'qwen3:8b',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsIdentifier('ai-assist-save-key'));
        await tester.pumpAndSettle();

        expect(
          await storage.readEndpoint(provider: AiProvider.ownServer),
          'http://192.168.1.9:11434/v1/chat/completions',
        );
        expect(
          await storage.readModel(provider: AiProvider.ownServer),
          'qwen3:8b',
        );
      });

      testWidgets('the system back button asks nothing either', (tester) async {
        // The same hole as Cancel, reached by the one exit that runs no
        // handler of ours at all. Driven through the real `show()` route,
        // because a dialog embedded in a body has nothing to pop.
        final server = _Server.listing(['gemma3:4b']);
        await storage.writeOwnServerConfiguration(
          endpoint: 'http://192.168.1.5:11434',
          model: 'gemma3:4b',
          provider: AiProvider.ownServer,
        );
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => AiAssistDialog.show(
                    context,
                    storage,
                    modelList: server.api,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await typeEndpoint(tester, 'http://192.168.1.9:11434');
        // What Android's back gesture delivers. `pageBack` looks for a back
        // button widget, and a dialog route has none.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(server.requests, isEmpty);
      });

      testWidgets('an address that is not a URL is refused before anything is '
          'sent', (tester) async {
        // The form Ollama's own documentation shows, and not a URL. The same
        // refusal OK gives, on the same field.
        final server = _Server.listing(['gemma3:4b']);
        await tester.pumpWidget(_app(storage, modelList: server.api));
        await tester.pumpAndSettle();

        await typeEndpoint(tester, '192.168.1.5:11434');
        await pressLoad(tester);

        expect(server.requests, isEmpty);
        expect(find.text(l10nEn.aiAssistEndpointInvalidLabel), findsOneWidget);
      });

      testWidgets('a fetched list survives 2x German on a narrow phone', (
        tester,
      ) async {
        // The dialog has already overflowed once at this size, which is why a
        // fetched list is a dropdown rather than a row per model: an Ollama
        // host with twenty pulled models would otherwise push the disclosure
        // and the OK button off the screen.
        tester.view.physicalSize = const Size(320 * 3, 640 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.reset);

        final server = _Server.listing([
          'hf.co/unsloth/Qwen3-30B-A3B-Instruct-GGUF:Q4_K_XL',
          'gemma3:4b',
        ]);
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: _app(
              storage,
              locale: const Locale('de'),
              modelList: server.api,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // `https://`, so the guard passes it through without a DNS lookup —
        // a plaintext name would be resolved for real, and #758's refusal is
        // not what this test is measuring.
        await typeEndpoint(
          tester,
          'https://ein-sehr-langer-name.fritz.box:11434',
        );
        await pressLoad(tester);

        expect(tester.takeException(), isNull);
      });

      testWidgets('a fetched list survives 2x German on a Pixel 6', (
        tester,
      ) async {
        // The device this dialog's overflows have actually been found on, at
        // the text scale that found them. Two model ids at the length people
        // really pull, and the status line underneath them, are the widest
        // thing this section can be asked to render.
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.625;
        addTearDown(tester.view.reset);

        final server = _Server.listing([
          'hf.co/unsloth/Qwen3-30B-A3B-Instruct-2507-GGUF:Q4_K_XL',
          'qwen2.5-coder:14b-instruct-q4_K_M',
        ]);
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: _app(
              storage,
              locale: const Locale('de'),
              modelList: server.api,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await typeEndpoint(
          tester,
          'https://ein-sehr-langer-servername.fritz.box:11434',
        );
        await pressLoad(tester);
        await tester.ensureVisible(find.byType(DropdownButton<String>));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });

    group('the setup check (#780)', () {
      late _FakeProber prober;
      late AiEndpointProbeRunner runner;

      const textOnly = AiEndpointProbe(
        text: AiCapability.passed,
        photo: AiCapability.failed,
      );

      setUp(() {
        prober = _FakeProber(textOnly);
        runner = AiEndpointProbeRunner(storage, prober);
      });

      /// A saved, usable server, so the section is on screen without going
      /// through the save path first.
      Future<void> configure() => storage.writeOwnServerConfiguration(
        endpoint: 'http://192.168.1.5:11434',
        model: 'gemma3:4b',
        provider: AiProvider.ownServer,
      );

      /// The section sits below the model fields, so on the default test
      /// viewport the button is inside the dialog's scroll view and off
      /// screen. An unscrolled `tap` only warns about missing it, which would
      /// leave every assertion below describing a button nobody pressed.
      Future<void> tapRetry(WidgetTester tester) async {
        final retry = find.bySemanticsIdentifier('ai-assist-probe-run');
        await tester.ensureVisible(retry);
        await tester.pumpAndSettle();
        await tester.tap(retry);
        await tester.pumpAndSettle();
      }

      Future<void> fillAndSave(WidgetTester tester) async {
        await tester.enterText(
          find.bySemanticsIdentifier('ai-assist-endpoint-field'),
          'http://192.168.1.5:11434',
        );
        await tester.enterText(
          find.bySemanticsIdentifier('ai-assist-model-field'),
          'gemma3:4b',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10nEn.dialogOKLabel));
        await tester.pumpAndSettle();
      }

      testWidgets('saving does not wait on the check', (tester) async {
        // The acceptance criterion this whole design hangs off. #735: saving
        // succeeds on syntax exactly as it did before the check existed, and
        // the check runs behind it — otherwise the server's availability
        // becomes a precondition for saving an address, and someone
        // configuring the app away from their server cannot even set up the
        // text path that would have worked.
        //
        // The prober is held open for the entire test, so an `await` in
        // `_save` would leave the dialog on screen forever. `pumpAndSettle`
        // does not wait on futures, so this fails fast rather than hanging.
        prober.gate = Completer<void>();

        await tester.pumpWidget(_app(storage, probeRunner: runner));
        await tester.pumpAndSettle();
        await fillAndSave(tester);

        expect(
          find.byType(AiAssistDialog),
          findsNothing,
          reason: 'OK closed the dialog while the check was still running',
        );
        expect(
          await storage.readEndpoint(provider: AiProvider.ownServer),
          'http://192.168.1.5:11434/v1/chat/completions',
        );
        expect(prober.calls, 1, reason: 'and it really did start one');
      });

      testWidgets('the text result and the photo result are separate', (
        tester,
      ) async {
        // #735 reports per capability rather than as one combined verdict,
        // because "text works, photos do not" is the common case for a small
        // local model and one sentence cannot express it. Collapsing the two
        // into a single line fails here.
        await configure();
        await storage.writeProbe(textOnly, provider: AiProvider.ownServer);

        await tester.pumpWidget(_app(storage, probeRunner: runner));
        await tester.pumpAndSettle();

        expect(
          find.text(l10nEn.aiAssistProbePassedLabel),
          findsOneWidget,
          reason: 'the text capability passed and says so on its own',
        );
        expect(
          find.text(l10nEn.aiAssistProbePhotoFailedLabel),
          findsOneWidget,
          reason: 'and the photo capability failed, in the same breath',
        );
        expect(find.text(l10nEn.aiAssistProbeTextLabel), findsOneWidget);
        expect(find.text(l10nEn.aiAssistProbePhotoLabel), findsOneWidget);
      });

      testWidgets('"not checked yet" reads differently from "checked and '
          'failed"', (tester) async {
        // Two states, not one. Nothing about never having asked is an error:
        // there is nothing to dismiss and nothing to fix, and the answer is
        // the retry below rather than a change of configuration.
        await configure();

        await tester.pumpWidget(_app(storage, probeRunner: runner));
        await tester.pumpAndSettle();

        expect(find.text(l10nEn.aiAssistProbeUnknownLabel), findsNWidgets(2));
        expect(find.text(l10nEn.aiAssistProbeTextFailedLabel), findsNothing);
        expect(find.text(l10nEn.aiAssistProbePhotoFailedLabel), findsNothing);
        expect(
          find.bySemanticsIdentifier('ai-assist-probe-run'),
          findsOneWidget,
          reason: '"never ran" gets a retry',
        );
      });

      testWidgets('an unreachable server stays a state with a retry', (
        tester,
      ) async {
        // The endpoint may be perfectly capable and merely asleep, so nothing
        // conclusive is recorded and nothing is presented as a fault. What
        // the user gets back is the same offer to try again.
        await configure();
        prober.result = AiEndpointProbe.unknown;

        await tester.pumpWidget(_app(storage, probeRunner: runner));
        await tester.pumpAndSettle();
        await tapRetry(tester);

        expect(prober.calls, 1, reason: 'the retry really did run one');
        expect(find.text(l10nEn.aiAssistProbeUnknownLabel), findsNWidgets(2));
        expect(find.text(l10nEn.aiAssistProbeTextFailedLabel), findsNothing);
        final retry = tester.widget<TextButton>(
          find.descendant(
            of: find.bySemanticsIdentifier('ai-assist-probe-run'),
            matching: find.byType(TextButton),
          ),
        );
        expect(
          retry.onPressed,
          isNotNull,
          reason: 'an inconclusive answer must not consume the retry',
        );
      });

      testWidgets('a failed text check is reported and turns nothing off', (
        tester,
      ) async {
        // #735's asymmetry. The deterministic parser still produces the rows,
        // one sample line is thin evidence about a real meal, and taking the
        // feature away over it would remove something that costs nothing.
        // What it must not do is stay silent — that is the
        // silent-parser-forever trap a mistyped key already sprang on a
        // Pixel 6.
        await configure();
        await storage.writeProbe(
          const AiEndpointProbe(
            text: AiCapability.failed,
            photo: AiCapability.passed,
          ),
          provider: AiProvider.ownServer,
        );

        await tester.pumpWidget(_app(storage, probeRunner: runner));
        await tester.pumpAndSettle();

        expect(find.text(l10nEn.aiAssistProbeTextFailedLabel), findsOneWidget);
        expect(await storage.isEnabled(), isTrue);
        expect((await storage.readSummary()).configured, isTrue);
        expect(
          find.bySemanticsIdentifier('ai-assist-enabled'),
          findsOneWidget,
          reason: 'the feature is still on, and still the user\'s to pause',
        );
      });

      testWidgets('re-running updates what is shown without a re-save', (
        tester,
      ) async {
        await configure();
        final saved = await storage.readEndpoint(
          provider: AiProvider.ownServer,
        );

        await tester.pumpWidget(_app(storage, probeRunner: runner));
        await tester.pumpAndSettle();
        expect(find.text(l10nEn.aiAssistProbeUnknownLabel), findsNWidgets(2));

        await tapRetry(tester);

        expect(find.text(l10nEn.aiAssistProbePassedLabel), findsOneWidget);
        expect(find.text(l10nEn.aiAssistProbePhotoFailedLabel), findsOneWidget);
        expect(
          await storage.readEndpoint(provider: AiProvider.ownServer),
          saved,
          reason: 'nothing was re-saved to get a fresh answer',
        );
      });

      testWidgets('a check still running is not reported as never run', (
        tester,
      ) async {
        // The reopened-mid-check case, which is the ordinary one: the user
        // pressed OK, walked away, and came back inside the 66 seconds.
        // Saying "not checked yet" here would offer a retry that silently
        // joins the running probe and looks like it did nothing.
        await configure();
        prober.gate = Completer<void>();
        unawaited(runner.start(AiProvider.ownServer));

        await tester.pumpWidget(_app(storage, probeRunner: runner));
        await tester.pumpAndSettle();

        expect(find.text(l10nEn.aiAssistProbeRunningLabel), findsOneWidget);
        final retry = tester.widget<TextButton>(
          find.descendant(
            of: find.bySemanticsIdentifier('ai-assist-probe-run'),
            matching: find.byType(TextButton),
          ),
        );
        expect(retry.onPressed, isNull, reason: 'one at a time');

        // And it catches up live if they are still looking when it lands.
        prober.gate!.complete();
        await tester.pumpAndSettle();
        expect(find.text(l10nEn.aiAssistProbeRunningLabel), findsNothing);
        expect(find.text(l10nEn.aiAssistProbePassedLabel), findsOneWidget);
      });

      testWidgets('an address that will be refused says so before saving', (
        tester,
      ) async {
        // #758's guard is the guarantee and refuses this per request. What is
        // folded in here is only that a *literal* address needs no lookup to
        // judge, so the one refusal that can be shown at save time is —
        // instead of storing a configuration whose only symptom is offline
        // parser rows forever.
        await tester.pumpWidget(_app(storage, probeRunner: runner));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.bySemanticsIdentifier('ai-assist-endpoint-field'),
          'http://93.184.216.34:11434',
        );
        await tester.enterText(
          find.bySemanticsIdentifier('ai-assist-model-field'),
          'gemma3:4b',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10nEn.dialogOKLabel));
        await tester.pumpAndSettle();

        expect(
          find.text(l10nEn.aiAssistEndpointPublicPlaintextLabel),
          findsOneWidget,
        );
        expect(await storage.readEndpoint(provider: AiProvider.ownServer),
            isNull);
        expect(prober.calls, 0, reason: 'nothing was configured to check');
      });

      testWidgets('a private address is not refused, and https is not '
          'either', (tester) async {
        await tester.pumpWidget(_app(storage, probeRunner: runner));
        await tester.pumpAndSettle();
        await fillAndSave(tester);

        expect(
          find.text(l10nEn.aiAssistEndpointPublicPlaintextLabel),
          findsNothing,
        );
        expect(
          await storage.readEndpoint(provider: AiProvider.ownServer),
          'http://192.168.1.5:11434/v1/chat/completions',
        );
      });

      testWidgets('a name is left to the guard rather than judged here', (
        tester,
      ) async {
        // `http://ollama.lan` is what people configure, and where it points
        // is a question with a network round trip in it. Answering it at save
        // time would make saving wait on the network, which is the one thing
        // #735 forbids — so the name is saved and refused per request if it
        // turns out to resolve somewhere public.
        await tester.pumpWidget(_app(storage, probeRunner: runner));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.bySemanticsIdentifier('ai-assist-endpoint-field'),
          'http://ollama.lan:11434',
        );
        await tester.enterText(
          find.bySemanticsIdentifier('ai-assist-model-field'),
          'gemma3:4b',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10nEn.dialogOKLabel));
        await tester.pumpAndSettle();

        expect(
          find.text(l10nEn.aiAssistEndpointPublicPlaintextLabel),
          findsNothing,
        );
        expect(
          await storage.readEndpoint(provider: AiProvider.ownServer),
          'http://ollama.lan:11434/v1/chat/completions',
        );
      });

      testWidgets('2x German on a handset viewport does not overflow', (
        tester,
      ) async {
        // The dialog has already overflowed once at 2x German, which is why
        // its title carries no Experimental badge. Two failure sentences are
        // the longest thing this section can render, so they are what gets
        // measured.
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.625;
        addTearDown(tester.view.reset);

        await storage.writeOwnServerConfiguration(
          endpoint: 'http://ein-sehr-langer-servername.fritz.box:11434',
          model: 'gemma3:4b',
          provider: AiProvider.ownServer,
        );
        await storage.writeProbe(
          const AiEndpointProbe(
            text: AiCapability.failed,
            photo: AiCapability.failed,
          ),
          provider: AiProvider.ownServer,
        );

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: _app(
              storage,
              locale: const Locale('de'),
              probeRunner: runner,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });
  });

  testWidgets('the check belongs to the server the user runs, and nowhere '
      'else', (tester) async {
    // The hosted three were screened behaviourally over live calls before
    // they were ever offered (#735), so there is nothing here a check would
    // establish that the curated list does not already carry — and an inert
    // "not checked yet" on the Anthropic path would imply otherwise.
    final runner = AiEndpointProbeRunner(
      storage,
      _FakeProber(AiEndpointProbe.unknown),
    );
    await storage.writeApiKey('sk-test', provider: AiProvider.anthropic);

    await tester.pumpWidget(_app(storage, probeRunner: runner));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.aiAssistProbeSectionLabel), findsNothing);
    expect(find.bySemanticsIdentifier('ai-assist-probe-run'), findsNothing);
  });

  testWidgets('the key field is on screen without scrolling, on a phone', (
    tester,
  ) async {
    // Found on a Pixel 6, not here. The original layout put the disclosure
    // above the field, and on the OpenRouter path — whose disclosure is
    // three sentences longer — that pushed the field entirely below the
    // fold. The dialog ended with a paragraph cut off mid-word and no
    // scroll affordance, so a first-time user saw a wall of text, ABBRECHEN
    // and OK, and no way to enter anything.
    //
    // `find.byType(TextField)` passed throughout, because a widget scrolled
    // out of view is still in the tree. Only its rect tells the truth.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await storage.setActiveProvider(AiProvider.openrouter);
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    final field = tester.getRect(find.byType(TextField));
    final viewport = tester.view.physicalSize.height / tester.view.devicePixelRatio;

    expect(
      field.bottom,
      lessThanOrEqualTo(viewport),
      reason: 'the key field must be reachable without scrolling: it is the '
          'one thing this dialog exists for',
    );
  });

  testWidgets('says that the content scrolls, rather than clipping it', (
    tester,
  ) async {
    // The disclosure cannot be made to fit a phone dialog — every sentence
    // in the OpenRouter one is load-bearing, and on a Pixel 6 the shared
    // paragraph starts below the fold. Clipped against the bottom edge with
    // no affordance it reads as the end of the text, which is the one thing
    // a disclosure must not do.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await storage.setActiveProvider(AiProvider.openrouter);
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    final scrollbar = tester.widget<Scrollbar>(find.byType(Scrollbar));
    expect(
      scrollbar.thumbVisibility,
      isTrue,
      reason: 'a disclosure that silently continues below the fold is a '
          'disclosure the reader thinks they have finished',
    );
  });

  testWidgets('the key field is obscured while typing', (tester) async {
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, isTrue);
    expect(field.autocorrect, isFalse);
    // Keyboard suggestion history is a plausible place for a pasted
    // credential to end up.
    expect(field.enableSuggestions, isFalse);
  });

  testWidgets('saving a key stores it and turns the feature on', (
    tester,
  ) async {
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'sk-test');
    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();

    expect(await storage.readApiKey(), 'sk-test');
    expect(await storage.isEnabled(), isTrue);
  });

  testWidgets('a saved key is never shown back, only masked', (tester) async {
    await storage.writeApiKey('sk-secret-value');
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    expect(find.textContaining('sk-secret-value'), findsNothing);
    expect(
      find.textContaining(AiCredentialStorage.maskedPlaceholder),
      findsOneWidget,
    );
    // No way to type over it without removing it first.
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('pausing keeps the key so re-enabling is one tap', (
    tester,
  ) async {
    await storage.writeApiKey('sk-test');
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(await storage.isEnabled(), isFalse);
    expect(await storage.readApiKey(), 'sk-test');
  });

  testWidgets('removing the key clears it and offers the field again', (
    tester,
  ) async {
    await storage.writeApiKey('sk-test');
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text(l10nEn.aiAssistRemoveKeyLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.aiAssistRemoveKeyLabel));
    await tester.pumpAndSettle();

    expect(await storage.hasApiKey(), isFalse);
    expect(await storage.isEnabled(), isFalse);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('cancelling without typing stores nothing', (tester) async {
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10nEn.dialogCancelLabel));
    await tester.pumpAndSettle();

    expect(backing.store, isEmpty);
  });

  testWidgets('a long saved-key label does not overflow its row', (
    tester,
  ) async {
    // AGENTS.md: a title in a Row has to survive a long localized string and
    // a large system font without RenderFlex stripes.
    await storage.writeApiKey('sk-test');
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: _app(storage),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  /// The model rows, and the paragraph each one actually painted.
  List<(String, RenderParagraph)> modelTitles(WidgetTester tester) => tester
      .widgetList<RadioListTile<String>>(find.byType(RadioListTile<String>))
      .map((tile) => (tile.title as Text).data!)
      .map((data) => (data, tester.renderObject<RenderParagraph>(
            find.text(data),
          )))
      .toList();

  test('provider identifiers are kebab-case, and one per provider', () {
    // `ownServer` shipped as `ai-assist-provider-ownServer`. Three of the
    // four enum names are a single lowercase word, so they satisfied
    // AGENTS.md by accident and nothing was watching when the fourth did
    // not — the adb verifier greps these, and a fifth provider is likelier
    // to be two words than one.
    final identifiers = AiProvider.values
        .map(AiAssistDialog.providerIdentifier)
        .toList();

    for (final identifier in identifiers) {
      expect(identifier, matches(RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$')));
    }
    expect(identifiers.toSet(), hasLength(identifiers.length));
    expect(
      AiAssistDialog.providerIdentifier(AiProvider.ownServer),
      'ai-assist-provider-own-server',
    );
  });

  test('model identifiers are kebab-case and one per model', () {
    // AGENTS.md asks for kebab-case, and a model id is not: it carries a
    // slash and a dot. The fold has to keep them apart as well as tidy —
    // two models landing on one identifier would make the adb verifier tap
    // a row it was not asked for and then report that it passed.
    final identifiers = [
      ...AiModelCatalogue.openrouter,
      ...AiModelCatalogue.anthropic,
    ].map((model) => AiAssistDialog.modelIdentifier(model.id)).toList();

    for (final identifier in identifiers) {
      expect(identifier, matches(RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$')));
    }
    expect(identifiers.toSet(), hasLength(identifiers.length));
  });

  testWidgets('the model rows carry the identifier the verifier looks for', (
    tester,
  ) async {
    await storage.setActiveProvider(AiProvider.openrouter);
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    for (final model in AiModelCatalogue.openrouter) {
      expect(
        find.bySemanticsIdentifier(AiAssistDialog.modelIdentifier(model.id)),
        findsOneWidget,
        reason: '${model.id} has no row the driver can find',
      );
    }
  });

  testWidgets('a model row stays inside its two-line bound', (tester) async {
    // 320dp at a 2.0 text scale leaves the title 156dp, which no model id
    // fits under any setting. What has to hold there is that it stops at the
    // bound rather than running down the dialog.
    //
    // Counted in painted lines rather than checked for overflow stripes: a
    // wrapping ListTile title throws nothing at all, so the exception check
    // the test above stays green through exactly this bug.
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await storage.setActiveProvider(AiProvider.openrouter);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: _app(storage),
      ),
    );
    await tester.pumpAndSettle();

    final titles = modelTitles(tester);
    expect(titles, hasLength(AiModelCatalogue.openrouter.length));

    for (final (data, paragraph) in titles) {
      final lines = paragraph
          .getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: data.length),
          )
          .map((box) => box.top)
          .toSet();
      expect(lines.length, lessThanOrEqualTo(2), reason: '$data ran past two');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('on a real phone the ids are whole and tell the rows apart', (
    tester,
  ) async {
    // A Pixel 6, which is the phone this was driven on. The ellipsis eats
    // the *end* of the string and the curated ids are identical until their
    // last few characters, so a title with too little room fails by painting
    // the same visible text in both rows — worse than wrapping, and just as
    // silent.
    //
    // This is what pins the vendor prefix in place. Dropping it looks like
    // it buys width and instead removes the `/`, which is the only point in
    // a model id where a line can break at all — so the shortened form
    // cannot use the second line, and truncates here where the full id fits.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await storage.setActiveProvider(AiProvider.openrouter);
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    final titles = modelTitles(tester);
    for (final (data, paragraph) in titles) {
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason: '$data was truncated on the phone this app is developed on',
      );
    }
    expect(
      titles.map((title) => title.$1).toSet(),
      hasLength(titles.length),
      reason: 'two rows painted the same text',
    );
  });
}
