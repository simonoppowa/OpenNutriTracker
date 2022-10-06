import 'package:hive/hive.dart';
import 'package:opennutritracker/core/data/dbo/product_dbo.dart';

part 'intake_dbo.g.dart';

@HiveType(typeId: 0)
class IntakeDBO extends HiveObject {
  @HiveField(0)
  String unit;
  @HiveField(1)
  double amount;

  @HiveField(2)
  ProductDBO product;

  IntakeDBO(this.unit, this.amount, this.product);
}
