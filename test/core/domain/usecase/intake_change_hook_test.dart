import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

class _Repository implements IntakeRepository {
  @override
  Future<void> addIntake(IntakeEntity intakeEntity) async {}

  @override
  Future<void> deleteIntake(IntakeEntity intakeEntity) async {}

  @override
  Future<IntakeEntity?> updateIntake(
    String intakeId,
    Map<String, dynamic> fields,
  ) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _intake = IntakeEntity(
  id: 'i',
  unit: 'g',
  amount: 100,
  type: IntakeTypeEntity.lunch,
  meal: MealEntity.empty(),
  dateTime: DateTime(2026, 10, 21, 12),
);

void main() {
  test(
    'adding, changing and deleting an entry report the change (#72)',
    () async {
      var changes = 0;
      void onChanged() => changes++;

      await AddIntakeUsecase(
        _Repository(),
        onChanged: onChanged,
      ).addIntake(_intake);
      await UpdateIntakeUsecase(
        _Repository(),
        onChanged: onChanged,
      ).updateIntake('i', {'amount': 50});
      await DeleteIntakeUsecase(
        _Repository(),
        onChanged: onChanged,
      ).deleteIntake(_intake);

      expect(changes, 3);
    },
  );

  test('without a listener nothing happens', () async {
    await AddIntakeUsecase(_Repository()).addIntake(_intake);
  });
}
