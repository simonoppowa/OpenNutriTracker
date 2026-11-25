import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/utils/app_locale.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/food_rpc_client.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/offline_food_db/sqlite_food_rpc_client.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../helpers/hive_test_setup.dart';
import 'fixture_db.dart';

class _TestHiveDBProvider extends HiveDBProvider {
  final Box<ConfigDBO> shared;
  final Box<ConfigDBO> profile;
  _TestHiveDBProvider(this.shared, this.profile);

  @override
  Box<ConfigDBO> get appConfigBox => shared;

  @override
  Box<ConfigDBO> get configBox => profile;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late Database db;

  setUpAll(() {
    dir = Directory.systemTemp.createTempSync('offline_food_db_source');
    db = openFixture(dir);
  });

  tearDownAll(() {
    db.close();
    dir.deleteSync(recursive: true);
  });

  setUp(() async {
    Hive.init(dir.path);
    registerHiveAdaptersOnce();
    final tag = DateTime.now().microsecondsSinceEpoch;
    locator.registerSingleton<ConfigDataSource>(
      ConfigDataSource(
        _TestHiveDBProvider(
          await Hive.openBox<ConfigDBO>('offline_app_$tag'),
          await Hive.openBox<ConfigDBO>('offline_cfg_$tag'),
        ),
      ),
    );
    locator.registerSingleton<FoodRpcClient>(SqliteFoodRpcClient(db));
  });

  tearDown(() async {
    AppLocale.reset();
    locator.unregister<FoodRpcClient>();
    locator.unregister<ConfigDataSource>();
    await Hive.deleteFromDisk();
  });

  test('English search ranks and parses the offline rows', () async {
    AppLocale.select('en');
    final foods = await SpFoodDataSource().fetchSearchWordResults('potato');

    expect(foods.map((f) => f.foodId), containsAll([1001, 1002, 1006]));
    final nfs = foods.firstWhere((f) => f.foodId == 1001);
    expect(nfs.name, 'Potato, NFS');
    expect(nfs.hasPortion, isTrue);
    expect(nfs.energyKcal100, 77.0);
    expect(nfs.localizedName, isNull);
  });

  test('German search goes through the translations', () async {
    AppLocale.select('de');
    final foods = await SpFoodDataSource().fetchSearchWordResults('kartoffel');

    // The app's own cut reorders the backend's pool (shorter first).
    expect(foods.map((f) => f.foodId), [1006, 1001]);
    final nfs = foods.last;
    expect(nfs.localizedName, 'Kartoffel, NFS');
    expect(nfs.displayNameIsMachineTranslated, isTrue);
    expect(nfs.name, 'Potato, NFS');
  });

  test('portions and portion labels parse as the backend\'s', () async {
    AppLocale.select('de');
    final source = SpFoodDataSource();

    final portions = await source.fetchPortions([1001, 50000001, 1006]);
    expect(portions, isNotNull);
    expect(portions!.keys, [1001, 50000001]);
    final cup = portions[1001]!.single;
    expect(cup.label, '1 Tasse');
    expect(cup.gramWeight, 150.0);
    expect(cup.localized, isTrue);
    expect(cup.englishLabel, '1 cup');
    expect(portions[50000001]!.map((p) => (p.label, p.localized)), [
      ('1 slice', false),
      ('1 Stück', true),
    ]);

    expect(await source.fetchPortionLabels([1001, 1002, 50000001]), {
      1001: '1 Tasse',
      1002: '1 mittelgroßes',
    });
  });
}
