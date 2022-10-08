import 'package:hive/hive.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/product_dbo.dart';

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

  IntakeDBO(
      {required this.unit,
      required this.amount,
      required this.type,
      required this.product});
}
