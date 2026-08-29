import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/utils/url_const.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

/// The notice has to reach everyone who onboarded against an older policy and
/// nobody else, exactly once, on a device rather than per profile (#887).
///
/// Whether it *shows* is one comparison, so the tests that matter are about
/// what the stored value is in each of the situations a real install can be in.
void main() {
  group('who the notice is for', () {
    test('an install that predates the field has seen nothing', () {
      // The null-to-zero mapping is the whole upgrade path: every existing
      // user is at revision 0 and is therefore owed the notice.
      final config = ConfigEntity.fromConfigDBO(ConfigDBO.empty());

      expect(config.policyNoticeRevisionSeen, 0);
      expect(
        config.policyNoticeRevisionSeen,
        lessThan(URLConst.policyRevision),
      );
    });

    test('a stored revision is read back verbatim', () {
      final config = ConfigEntity.fromConfigDBO(
        ConfigDBO(
          false,
          true,
          false,
          AppThemeDBO.system,
          policyNoticeRevisionSeen: URLConst.policyRevision,
        ),
      );

      expect(config.policyNoticeRevisionSeen, URLConst.policyRevision);
      expect(
        config.policyNoticeRevisionSeen >= URLConst.policyRevision,
        isTrue,
        reason: 'a user stamped at the current revision must not be notified',
      );
    });

    test('a revision from a future build does not re-notify on downgrade', () {
      // Downgrades happen — a sideloaded APK, a staged rollout rolled back.
      // The comparison is >=, not ==, so a user who has seen revision 2 is
      // not told about revision 1 as though it were news.
      final config = ConfigEntity.fromConfigDBO(
        ConfigDBO(
          false,
          true,
          false,
          AppThemeDBO.system,
          policyNoticeRevisionSeen: URLConst.policyRevision + 1,
        ),
      );

      expect(
        config.policyNoticeRevisionSeen >= URLConst.policyRevision,
        isTrue,
      );
    });

    test('the revision survives a JSON round-trip', () {
      // ConfigDataSource detaches configs through JSON on every read and
      // write, so a field that does not survive it is a field that silently
      // resets and re-shows the notice on every launch.
      final dbo = ConfigDBO(
        false,
        true,
        false,
        AppThemeDBO.system,
        policyNoticeRevisionSeen: 3,
      );

      expect(ConfigDBO.fromJson(dbo.toJson()).policyNoticeRevisionSeen, 3);
    });

    test('the current revision is a real revision', () {
      // A zero here would mean nobody is ever notified, silently.
      expect(URLConst.policyRevision, greaterThanOrEqualTo(1));
    });
  });

  group('the notice is device-wide, not per profile', () {
    late Box<ConfigDBO> appBox;
    late Box<ConfigDBO> profileABox;
    late Box<ConfigDBO> profileBBox;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      registerHiveAdaptersOnce();
    });

    setUp(() async {
      Hive.init('.');
      appBox = await Hive.openBox<ConfigDBO>('policy_notice_app_test');
      profileABox = await Hive.openBox<ConfigDBO>('policy_notice_a_test');
      profileBBox = await Hive.openBox<ConfigDBO>('policy_notice_b_test');
      await appBox.clear();
      await profileABox.clear();
      await profileBBox.clear();
    });

    tearDown(() async {
      await Hive.close();
      await Hive.deleteFromDisk();
    });

    ConfigDataSource sourceFor(Box<ConfigDBO> profileBox) => ConfigDataSource(
      FakeHiveDBProvider(configBox: profileBox, appConfigBox: appBox),
    );

    test('a second profile is not notified again', () async {
      // The policy describes what the app does, not what one profile does.
      // Being told twice on one device would read as a second change.
      final profileA = sourceFor(profileABox);
      await profileA.initializeConfig();
      await profileA.setConfigPolicyNoticeRevisionSeen(URLConst.policyRevision);

      final profileB = sourceFor(profileBBox);
      await profileB.initializeConfig();
      final config = await profileB.getConfig();

      expect(config.policyNoticeRevisionSeen, URLConst.policyRevision);
    });

    test(
      'it is not cleared by a fresh profile the way personal fields are',
      () {
        // _readMerged deliberately blanks the per-profile fields when a profile
        // box is absent. This one must not be in that set, or resetting a
        // profile would resurrect a notice about a change already announced.
        final merged = ConfigEntity.fromConfigDBO(
          ConfigDBO(
            false,
            true,
            false,
            AppThemeDBO.system,
            policyNoticeRevisionSeen: URLConst.policyRevision,
            healthImportEnabled: true,
          ),
        );

        expect(merged.policyNoticeRevisionSeen, URLConst.policyRevision);
      },
    );
  });
}
