import 'package:hive/hive.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/product_dbo.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';

part 'intake_dbo.g.dart';

@HiveType(typeId: 0)
class IntakeDBO extends HiveObject {
  @HiveField(0)
  String unit;
  @HiveField(1)
  double amount;
  @HiveField(2)
  IntakeTypeDBO type;

  @HiveField(3)
  ProductDBO product;

  @HiveField(4)
  DateTime dateTime;

  IntakeDBO(
      {required this.unit,
      required this.amount,
      required this.type,
      required this.product,
      required this.dateTime});

  factory IntakeDBO.fromIntakeEntity(IntakeEntity entity) {
    return IntakeDBO(
        unit: entity.unit,
        amount: entity.amount,
        type: IntakeTypeDBO.fromIntakeTypeEntity(entity.type),
        product: ProductDBO.fromProductEntity(entity.product),
        dateTime: entity.dateTime);
  }
}
