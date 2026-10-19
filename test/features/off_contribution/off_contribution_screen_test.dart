import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/off_contribution/data/off_contribution_settings.dart';
import 'package:opennutritracker/features/off_contribution/presentation/off_contribution_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../helpers/test_l10n.dart';

class _MemoryStore extends OffContributionSettingsStore {
  OffContributionSettings settings = const OffContributionSettings();

  _MemoryStore() : super(const FlutterSecureStorage());

  @override
  Future<OffContributionSettings> load() async => settings;

  @override
  Future<void> save(OffContributionSettings settings) async =>
      this.settings = settings;
}

void main() {
  testWidgets('stores the switch, the account and the server', (tester) async {
    final store = _MemoryStore();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: OffContributionScreen(store: store),
      ),
    );
    await tester.pumpAndSettle();

    expect(store.settings.enabled, isFalse);
    await tester.tap(find.text(l10nEn.offContributionEnable));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, l10nEn.offContributionUserId),
      'theo',
    );
    await tester.enterText(
      find.widgetWithText(TextField, l10nEn.offContributionPassword),
      's3cret',
    );
    await tester.pumpAndSettle();

    expect(store.settings.enabled, isTrue);
    expect(store.settings.userId, 'theo');
    expect(store.settings.password, 's3cret');
    expect(store.settings.useTestServer, isTrue);

    await tester.tap(find.text(l10nEn.offContributionTestServer));
    await tester.pumpAndSettle();

    expect(store.settings.useTestServer, isFalse);
    expect(store.settings.isReady, isTrue);
  });
}
