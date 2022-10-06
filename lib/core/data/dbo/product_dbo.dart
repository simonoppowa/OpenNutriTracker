import 'package:hive_flutter/hive_flutter.dart';
import 'package:opennutritracker/features/addItem/domain/entity/product_entity.dart';

part 'product_dbo.g.dart';

@HiveType(typeId: 1)
class ProductDBO extends HiveObject {
  @HiveField(0)
  final String? code;
  @HiveField(1)
  final String? productName;
  @HiveField(2)
  final String? productNameEN;
  @HiveField(3)
  final String? productNameDE;

  @HiveField(4)
  final String? brands;

  @HiveField(5)
  final String? thumbnailImageUrl;
  @HiveField(6)
  final String? mainImageUrl;

  @HiveField(7)
  final String? url;

  @HiveField(8)
  final double? productQuantity;
  @HiveField(9)
  final String? productUnit;
  @HiveField(10)
  final double? servingQuantity;
  @HiveField(11)
  final String? servingUnit;

  ProductDBO(
      {required this.code,
      required this.productName,
      required this.productNameEN,
      required this.productNameDE,
      required this.brands,
      required this.thumbnailImageUrl,
      required this.mainImageUrl,
      required this.url,
      required this.productQuantity,
      required this.productUnit,
      required this.servingQuantity,
      required this.servingUnit});

  factory ProductDBO.fromProductEntity(ProductEntity productEntity) =>
      ProductDBO(
          code: productEntity.code,
          productName: productEntity.productName,
          productNameEN: productEntity.productNameEN,
          productNameDE: productEntity.productNameDE,
          brands: productEntity.brands,
          thumbnailImageUrl: productEntity.thumbnailImageUrl,
          mainImageUrl: productEntity.mainImageUrl,
          url: productEntity.url,
          productQuantity: productEntity.productQuantity,
          productUnit: productEntity.productUnit,
          servingQuantity: productEntity.servingQuantity,
          servingUnit: productEntity.servingUnit);
}
