import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

// Official pre-view records own field 42 and have no field 43.
class _OfficialConfigAdapter extends TypeAdapter<ConfigDBO> {
  @override
  int get typeId => 13;

  @override
  ConfigDBO read(BinaryReader reader) => ConfigDBOAdapter().read(reader);

  @override
  void write(BinaryWriter writer, ConfigDBO obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.hasAcceptedDisclaimer)
      ..writeByte(1)
      ..write(obj.hasAcceptedPolicy)
      ..writeByte(2)
      ..write(obj.hasAcceptedSendAnonymousData)
      ..writeByte(3)
      ..write(obj.selectedAppTheme)
      ..writeByte(13)
      ..write(obj.selectedLocale)
      ..writeByte(42)
      ..write(obj.hasLeftTip);
  }
}

void main() {
  late Directory directory;
  late Box<ConfigDBO> box;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('config-view-compat-');
    Hive.init(directory.path);
    registerHiveAdaptersOnce();
    Hive.registerAdapter<ConfigDBO>(_OfficialConfigAdapter(), override: true);
    box = await Hive.openBox<ConfigDBO>('config');
  });

  tearDown(() async {
    await box.close();
    Hive.registerAdapter<ConfigDBO>(ConfigDBOAdapter(), override: true);
    await directory.delete(recursive: true);
  });

  for (final marker in [true, false]) {
    test(
      'official field42=$marker survives absent43 and independent view writes',
      () async {
        final original = ConfigDBO.empty()
          ..hasLeftTip = marker
          ..selectedLocale = 'de';
        await box.put('ConfigKey', original);
        await box.close();
        Hive.registerAdapter<ConfigDBO>(ConfigDBOAdapter(), override: true);
        box = await Hive.openBox<ConfigDBO>('config');

        ConfigDataSource configs() =>
            ConfigDataSource(FakeHiveDBProvider(configBox: box));
        expect(box.get('ConfigKey')!.hasLeftTip, marker);
        expect(box.get('ConfigKey')!.customMealNutrientsTotal, isNull);
        expect(await configs().getCustomMealNutrientsTotal(), isFalse);
        expect(await configs().getHasLeftTip(), marker);

        for (final total in [true, false]) {
          await configs().setCustomMealNutrientsTotal(total);
          await box.close();
          box = await Hive.openBox<ConfigDBO>('config');
          final restored = box.get('ConfigKey')!;
          expect(restored.hasLeftTip, marker);
          expect(restored.customMealNutrientsTotal, total);
          expect(restored.selectedLocale, original.selectedLocale);
          expect(
            restored.hasAcceptedDisclaimer,
            original.hasAcceptedDisclaimer,
          );
          expect(restored.hasAcceptedPolicy, original.hasAcceptedPolicy);
          expect(
            restored.hasAcceptedSendAnonymousData,
            original.hasAcceptedSendAnonymousData,
          );
          expect(await configs().getCustomMealNutrientsTotal(), total);
          expect(await configs().getHasLeftTip(), marker);
        }

        await configs().setHasLeftTip();
        await box.close();
        box = await Hive.openBox<ConfigDBO>('config');
        expect(await configs().getHasLeftTip(), isTrue);
        expect(await configs().getCustomMealNutrientsTotal(), isFalse);
      },
    );
  }
}
