import 'package:hive/hive.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/product_dbo.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';

part 'intake_dbo.g.dart';

@HiveType(typeId: 0)
class IntakeDBO extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String unit;
  @HiveField(2)
  double amount;
  @HiveField(3)
  IntakeTypeDBO type;

  @HiveField(4)
  ProductDBO product;

  @HiveField(5)
  DateTime dateTime;

  IntakeDBO(
      {required this.id,
      required this.unit,
      required this.amount,
      required this.type,
      required this.product,
      required this.dateTime});

  factory IntakeDBO.fromIntakeEntity(IntakeEntity entity) {
    return IntakeDBO(
        id: entity.id,
        unit: entity.unit,
        amount: entity.amount,
        type: IntakeTypeDBO.fromIntakeTypeEntity(entity.type),
        product: ProductDBO.fromProductEntity(entity.product),
        dateTime: entity.dateTime);
  }
}
