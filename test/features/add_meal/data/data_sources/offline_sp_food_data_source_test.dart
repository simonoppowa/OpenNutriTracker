import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/offline_sp_food_data_source.dart';

void main() {
  final dataSource = OfflineSpFoodDataSource();

  test('a search answers empty without a backend', () async {
    expect(await dataSource.fetchSearchWordResults('Haferflocken'), isEmpty);
    expect(
      await dataSource.fetchSearchWordResults('Apfel', forResolution: true),
      isEmpty,
    );
  });

  test('portion labels and portions answer empty', () async {
    expect(await dataSource.fetchPortionLabels([1, 2]), isEmpty);
    expect(await dataSource.fetchPortions([1, 2]), isEmpty);
  });
}
