import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/features/addItem/domain/entity/product_entity.dart';

class IntakeEntity {
  String unit;
  double amount;
  IntakeTypeEntity type;
  DateTime dateTime;

  ProductEntity product;

  IntakeEntity(
      {required this.unit,
      required this.amount,
      required this.type,
      required this.product,
      required this.dateTime});
}
