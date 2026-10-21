import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

class _Repository implements IntakeRepository {
  final List<IntakeDBO> intakes;

  _Repository(this.intakes);

  @override
  Future<List<IntakeDBO>> getAllIntakesDBO() async => intakes;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

IntakeDBO _intake(String id, DateTime at) => IntakeDBO(
  id: id,
  unit: 'g',
  amount: 100,
  type: IntakeTypeDBO.lunch,
  meal: MealDBO.fromMealEntity(MealEntity.empty()),
  dateTime: at,
);

void main() {
  final usecase = GetIntakeUsecase(
    _Repository([
      _intake('before', DateTime(2026, 10, 18, 23, 30)),
      _intake('mon-early', DateTime(2026, 10, 19, 2)),
      _intake('mon', DateTime(2026, 10, 19, 12)),
      _intake('tue', DateTime(2026, 10, 20, 19)),
      _intake('after', DateTime(2026, 10, 21, 8)),
    ]),
  );

  test('groups the entries of the period by day', () async {
    final byDay = await usecase.getIntakesByDayBetween(
      DateTime(2026, 10, 19),
      DateTime(2026, 10, 20),
    );

    expect(byDay.keys, {DateTime(2026, 10, 19), DateTime(2026, 10, 20)});
    expect(byDay[DateTime(2026, 10, 19)]!.map((i) => i.id), [
      'mon-early',
      'mon',
    ]);
    expect(byDay[DateTime(2026, 10, 20)]!.map((i) => i.id), ['tue']);
  });

  test('a later day start moves early entries to the day before', () async {
    final byDay = await usecase.getIntakesByDayBetween(
      DateTime(2026, 10, 19),
      DateTime(2026, 10, 20),
      dayStartOffsetHours: 4,
    );

    expect(byDay[DateTime(2026, 10, 19)]!.map((i) => i.id), ['mon']);
  });
}
