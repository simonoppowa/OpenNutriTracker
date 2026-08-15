import 'package:flutter/material.dart';
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

Widget _app(AiCredentialStorage storage) => MaterialApp(
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

  testWidgets('names the vendor that will actually serve the request', (
    tester,
  ) async {
    // Pinned with fallbacks off, so this is guaranteed rather than likely —
    // which is why it is stated once here instead of on every batch.
    await storage.setActiveProvider(AiProvider.openrouter);
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(l10nEn.aiAssistServedByLabel('Anthropic')),
      findsNWidgets(AiModelCatalogue.openrouter.length),
    );
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
}
