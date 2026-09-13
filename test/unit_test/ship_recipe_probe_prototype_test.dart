// PROTOTYPE probe for #1182 — what a device resolves to, before and after.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/l10n/app_locales.dart';
import 'package:opennutritracker/generated/l10n.dart';

void main() {
  test('resolution: gen-l10n list vs shipped subset', () {
    final generated = S.supportedLocales;
    final shipped = appLocales(generated);
    print('gen-l10n list (${generated.length}): $generated');
    print('shipped subset (${shipped.length}): $shipped');
    for (final dev in const [
      Locale('sv', 'SE'),
      Locale('es', 'ES'),
      Locale('fr', 'FR'),
      Locale('de', 'AT'),
      Locale('pt', 'BR'),
    ]) {
      final before = basicLocaleListResolution([dev], generated);
      final after = basicLocaleListResolution([dev], shipped);
      print('device=$dev  every-ARB -> $before   shipped-only -> $after');
    }
  });

  testWidgets('a Swedish device on "System" sees English; a French one French',
      (tester) async {
    for (final dev in const [Locale('sv', 'SE'), Locale('fr', 'FR')]) {
      tester.platformDispatcher.localesTestValue = [dev];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      late Locale resolved;
      late String add, cancel;
      await tester.pumpWidget(MaterialApp(
        locale: null,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: appLocales(S.supportedLocales),
        home: Builder(builder: (context) {
          resolved = Localizations.localeOf(context);
          add = S.of(context).addLabel;
          cancel = MaterialLocalizations.of(context).cancelButtonLabel;
          return const SizedBox();
        }),
      ));
      print('device=$dev -> resolved=$resolved  addLabel="$add"  cancel="$cancel"');
    }
  });
}
