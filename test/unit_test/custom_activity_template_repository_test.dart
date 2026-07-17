import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/custom_activity_template_data_source.dart';
import 'package:opennutritracker/core/data/data_source/custom_activity_template_dbo.dart';
import 'package:opennutritracker/core/data/repository/custom_activity_template_repository.dart';
import 'package:opennutritracker/core/domain/entity/custom_activity_template_entity.dart';

import '../helpers/hive_test_setup.dart';
import '../helpers/fake_hive_db_provider.dart';

void main() {
  group('CustomActivityTemplateRepository', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      registerHiveAdaptersOnce();
    });

    setUp(() {
      Hive.init('.');
    });

    tearDown(() async {
      await Hive.close();
      Hive.deleteFromDisk();
    });

    test('addTemplate persists and allTemplates returns it alphabetised',
        () async {
      // #70 follow-up: a saved template should make it back out of the
      // box with the same name, typical kcal, and optional notes, and
      // the listing should be alphabetised by name so the picker UI
      // doesn't have to do its own sort.
      final box = await Hive.openBox<CustomActivityTemplateDBO>(
        'template_test',
      );
      await box.clear();
      final repo = CustomActivityTemplateRepository(
        CustomActivityTemplateDataSource(FakeHiveDBProvider(customActivityTemplateBox: box)),
      );

      await repo.addTemplate(
        const CustomActivityTemplateEntity(
          name: 'Evening bike commute',
          typicalKcal: 240,
          notes: 'Home from the office, rough terrain',
        ),
      );
      await repo.addTemplate(
        const CustomActivityTemplateEntity(
          name: 'Climbing gym',
          typicalKcal: 480,
        ),
      );

      final templates = await repo.allTemplates();
      expect(templates, hasLength(2));
      expect(templates[0].name, equals('Climbing gym'));
      expect(templates[0].typicalKcal, equals(480));
      expect(templates[0].notes, isNull);
      expect(templates[1].name, equals('Evening bike commute'));
      expect(templates[1].typicalKcal, equals(240));
      expect(
        templates[1].notes,
        equals('Home from the office, rough terrain'),
      );
    });

    test('addTemplate with an existing name overwrites in place', () async {
      // Re-saving "Climbing gym" with a new kcal should keep one entry
      // rather than duplicate — users tweaking their typical kcal over
      // time shouldn't accumulate stale rows in the picker.
      final box = await Hive.openBox<CustomActivityTemplateDBO>(
        'template_test',
      );
      await box.clear();
      final repo = CustomActivityTemplateRepository(
        CustomActivityTemplateDataSource(FakeHiveDBProvider(customActivityTemplateBox: box)),
      );

      await repo.addTemplate(
        const CustomActivityTemplateEntity(
          name: 'Climbing gym',
          typicalKcal: 420,
        ),
      );
      await repo.addTemplate(
        const CustomActivityTemplateEntity(
          name: 'Climbing gym',
          typicalKcal: 510,
        ),
      );

      final templates = await repo.allTemplates();
      expect(templates, hasLength(1));
      expect(templates.single.typicalKcal, equals(510));
    });

    test('deleteTemplate removes by name', () async {
      final box = await Hive.openBox<CustomActivityTemplateDBO>(
        'template_test',
      );
      await box.clear();
      final repo = CustomActivityTemplateRepository(
        CustomActivityTemplateDataSource(FakeHiveDBProvider(customActivityTemplateBox: box)),
      );

      await repo.addTemplate(
        const CustomActivityTemplateEntity(
          name: 'Climbing gym',
          typicalKcal: 480,
        ),
      );
      await repo.addTemplate(
        const CustomActivityTemplateEntity(
          name: 'Yoga class',
          typicalKcal: 150,
        ),
      );

      await repo.deleteTemplate('Climbing gym');

      final templates = await repo.allTemplates();
      expect(templates.map((t) => t.name).toList(), equals(['Yoga class']));
    });

    test('addAllTemplateDBOs round-trips through the import path', () async {
      // The export bundle writes raw DBOs to JSON. The matching import
      // path adds them back via addAllTemplateDBOs, so a user moving
      // between devices keeps their saved templates intact.
      final box = await Hive.openBox<CustomActivityTemplateDBO>(
        'template_test',
      );
      await box.clear();
      final repo = CustomActivityTemplateRepository(
        CustomActivityTemplateDataSource(FakeHiveDBProvider(customActivityTemplateBox: box)),
      );

      final imported = [
        CustomActivityTemplateDBO('Evening bike commute', 240),
        CustomActivityTemplateDBO(
          'Climbing gym',
          480,
          notes: 'Bouldering session',
        ),
      ];

      await repo.addAllTemplateDBOs(imported);

      final templates = await repo.allTemplates();
      expect(templates, hasLength(2));
      // Alphabetised, so Climbing gym leads.
      expect(templates[0].name, equals('Climbing gym'));
      expect(templates[0].notes, equals('Bouldering session'));
      expect(templates[1].name, equals('Evening bike commute'));
    });

    test('a template round-trips through JSON without losing fields',
        () async {
      // The export/import bundle serialises templates as JSON. This
      // pins down that the JSON shape lines up with what fromJson
      // reads back, so the zip a user emails themselves between
      // devices stays compatible.
      final original = CustomActivityTemplateDBO(
        'Evening bike commute',
        240,
        notes: 'Rough terrain',
      );
      final roundTripped =
          CustomActivityTemplateDBO.fromJson(original.toJson());

      expect(roundTripped.name, equals('Evening bike commute'));
      expect(roundTripped.typicalKcal, equals(240));
      expect(roundTripped.notes, equals('Rough terrain'));
    });
  });
}
