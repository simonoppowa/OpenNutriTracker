// ignore_for_file: constant_identifier_names

import 'package:hive_flutter/hive_flutter.dart';
import 'package:opennutritracker/core/data/dbo/product_nutriments_dbo.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/product_entity.dart';

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
  final String? productQuantity;
  @HiveField(9)
  final String? productUnit;
  @HiveField(10)
  final double? servingQuantity;
  @HiveField(11)
  final String? servingUnit;

  @HiveField(12)
  final ProductSourceDBO source;

  @HiveField(13)
  final ProductNutrimentsDBO nutriments;

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
      required this.servingUnit,
      required this.nutriments,
      required this.source});

  factory ProductDBO.fromProductEntity(
          ProductEntity productEntity) =>
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
          servingUnit: productEntity.servingUnit,
          nutriments:
              ProductNutrimentsDBO.fromProductNutrimentsEntity(
                  productEntity.nutriments),
          source:
              ProductSourceDBO.fromProductSourceEntity(productEntity.source));
}

@HiveType(typeId: 14)
enum ProductSourceDBO {
  @HiveField(0)
  unknown,
  @HiveField(1)
  off,
  @HiveField(2)
  fdc;

  factory ProductSourceDBO.fromProductSourceEntity(ProductSourceEntity entity) {
    ProductSourceDBO productSourceDBO;
    switch (entity) {
      case ProductSourceEntity.unknown:
        productSourceDBO = ProductSourceDBO.unknown;
        break;
      case ProductSourceEntity.off:
        productSourceDBO = ProductSourceDBO.off;
        break;
      case ProductSourceEntity.fdc:
        productSourceDBO = ProductSourceDBO.fdc;
        break;
    }
    return productSourceDBO;
  }
}
