import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/features/home/domain/water_quick_amount.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/home/presentation/widgets/log_water_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../helpers/test_l10n.dart';

class _FakeHomeBloc implements HomeBloc {
  final added = <int>[];
  final deleted = <String>[];

  @override
  Future<String?> addWaterIntake(int amountMl) async {
    added.add(amountMl);
    return 'water-${added.length}';
  }

  @override
  Future<void> deleteWaterIntake(String id) async => deleted.add(id);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeConfigDataSource implements ConfigDataSource {
  ConfigDBO config = ConfigDBO(false, false, false, AppThemeDBO.system)
    ..waterQuickAmountMl = 750;

  @override
  Future<ConfigDBO> getConfig() async => config;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

void main() {
  final getIt = GetIt.instance;
  late _FakeHomeBloc home;

  setUp(() {
    home = _FakeHomeBloc();
    getIt.registerSingleton<HomeBloc>(home);
    getIt.registerSingleton(WaterQuickAmount(_FakeConfigDataSource()));
  });

  tearDown(() => getIt.reset());

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const LogWaterDialog(),
              ),
              child: const Text('water'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('water'));
    await tester.pumpAndSettle();
  }

  Finder quick(String id) => find.bySemanticsIdentifier('log-water-quick-$id');

  testWidgets('one tap on +250 ml logs 250 ml and closes the dialog', (
    tester,
  ) async {
    await openDialog(tester);

    await tester.tap(quick('250'));
    await tester.pumpAndSettle();

    expect(home.added, [250]);
    expect(find.byType(LogWaterDialog), findsNothing);
    expect(find.text(l10nEn.waterQuickAddedLabel(250)), findsOneWidget);
  });

  testWidgets('+500 ml logs 500 ml', (tester) async {
    await openDialog(tester);

    await tester.tap(quick('500'));
    await tester.pumpAndSettle();

    expect(home.added, [500]);
  });

  testWidgets('the third button uses the own amount', (tester) async {
    await openDialog(tester);

    expect(find.text('+750 ml'), findsOneWidget);
    await tester.tap(quick('custom'));
    await tester.pumpAndSettle();

    expect(home.added, [750]);
  });

  testWidgets('undo removes the entry again', (tester) async {
    await openDialog(tester);
    await tester.tap(quick('250'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10nEn.waterQuickUndoLabel));
    await tester.pumpAndSettle();

    expect(home.deleted, ['water-1']);
  });
}
