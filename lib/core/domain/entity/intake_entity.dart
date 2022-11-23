import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/product_entity.dart';

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

  factory IntakeEntity.fromIntakeDBO(IntakeDBO intakeDBO) {
    return IntakeEntity(
        unit: intakeDBO.unit,
        amount: intakeDBO.amount,
        type: IntakeTypeEntity.fromIntakeTypeDBO(intakeDBO.type),
        product: ProductEntity.fromProductDBO(intakeDBO.product),
        dateTime: intakeDBO.dateTime);
  }

  double get totalKcal => amount * (product.nutriments.energyPerUnit ?? 0);

  double get totalCarbsGram =>
      amount * (product.nutriments.carbohydratesPerUnit ?? 0);
  double get totalFatsGram =>
      amount * (product.nutriments.fatPerUnit ?? 0);
  double get totalProteinsGram =>
      amount * (product.nutriments.proteinsPerUnit ?? 0);
}
