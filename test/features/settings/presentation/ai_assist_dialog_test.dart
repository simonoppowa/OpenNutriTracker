import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/core/utils/ai_model_catalogue.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/ai_assist_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../helpers/test_l10n.dart';

class _MemoryStorage implements FlutterSecureStorage {
  final store = <String, String>{};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => store[key];

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

Widget _app(AiCredentialStorage storage, {Locale? locale}) => MaterialApp(
  locale: locale,
  localizationsDelegates: const [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: S.supportedLocales,
  home: Scaffold(body: AiAssistDialog(storage: storage)),
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
      expect(
        find.textContaining('not encrypted'),
        findsWidgets,
        reason: 'the dialog is the only place a user learns this',
      );

      await tester.enterText(
        find.bySemanticsIdentifier('ai-assist-endpoint-field'),
        'https://ollama.example.com',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('not encrypted'), findsNothing);
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

      expect(await storage.readEndpoint(provider: AiProvider.ownServer),
          'http://192.168.1.5:11434');
      expect(await storage.readModel(provider: AiProvider.ownServer),
          'gemma3:4b');
      expect(
        (await storage.readSummary()).configured,
        isTrue,
        reason: 'no key was entered, and none is needed',
      );
    });

    testWidgets('survives 2x German on a narrow phone', (tester) async {
      // Where this dialog's title lost its Experimental badge for
      // overflowing by 48px. A user-supplied hostname is less bounded than
      // anything else it renders, so this is measured rather than assumed.
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await storage.writeEndpoint(
        'http://ein-sehr-langer-servername.fritz.box:11434',
        provider: AiProvider.ownServer,
      );
      await tester.pumpWidget(_app(storage, locale: const Locale('de')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
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
