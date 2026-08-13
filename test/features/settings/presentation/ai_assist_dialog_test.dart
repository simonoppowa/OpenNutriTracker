import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
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

    expect(find.text(l10nEn.aiAssistDisclosureLabel), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
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
}
