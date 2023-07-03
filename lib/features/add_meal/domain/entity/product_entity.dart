import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/product_dbo.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_food.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off_product.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/product_nutriments_entity.dart';

// TODO rename
class ProductEntity extends Equatable{
  final String? code;
  final String? productName;
  final String? productNameEN;
  final String? productNameDE;

  final String? brands;

  final String? thumbnailImageUrl;
  final String? mainImageUrl;

  final String? url;

  final String? productQuantity;
  final String? productUnit;
  final double? servingQuantity;
  final String? servingUnit;

  final ProductSourceEntity source;

  final ProductNutrimentsEntity nutriments;

  const ProductEntity(
      {required this.code,
      required this.productName,
      this.productNameEN,
      this.productNameDE,
      this.brands,
      this.thumbnailImageUrl,
      this.mainImageUrl,
      required this.url,
      required this.productQuantity,
      required this.productUnit,
      required this.servingQuantity,
      required this.servingUnit,
      required this.nutriments,
      required this.source});

  factory ProductEntity.fromProductDBO(ProductDBO productDBO) => ProductEntity(
      code: productDBO.code,
      productName: productDBO.productName,
      productNameEN: productDBO.productNameEN,
      productNameDE: productDBO.productNameDE,
      brands: productDBO.brands,
      thumbnailImageUrl: productDBO.thumbnailImageUrl,
      mainImageUrl: productDBO.mainImageUrl,
      url: productDBO.url,
      productQuantity: productDBO.productQuantity,
      productUnit: productDBO.productUnit,
      servingQuantity: productDBO.servingQuantity,
      servingUnit: productDBO.servingUnit,
      nutriments: ProductNutrimentsEntity.fromProductNutrimentsDBO(
          productDBO.nutriments),
      source: ProductSourceEntity.fromProductSourceDBO(productDBO.source));

  factory ProductEntity.fromOFFProduct(OFFProduct offProduct) {
    return ProductEntity(
        code: offProduct.code,
        productName: offProduct.product_name ??
            offProduct.product_name_fr ??
            offProduct.product_name_en ??
            offProduct.product_name_de ??
            offProduct.brands,
        productNameEN: offProduct.product_name_en,
        productNameDE: offProduct.product_name_de,
        brands: offProduct.brands,
        thumbnailImageUrl: offProduct.image_front_thumb_url,
        mainImageUrl: offProduct.image_front_url,
        url: offProduct.url,
        productQuantity: offProduct.product_quantity?.toString(),
        productUnit: _tryGetUnit(offProduct.quantity),
        servingQuantity: _tryQuantityCast(offProduct.serving_quantity),
        servingUnit: _tryGetUnit(offProduct.quantity),
        nutriments:
            ProductNutrimentsEntity.fromOffNutriments(offProduct.nutriments),
        source: ProductSourceEntity.off);
  }

  factory ProductEntity.fromFDCFood(FDCFood fdcFood) {
    final fdcId = fdcFood.fdcId?.toInt().toString();

    return ProductEntity(
        code: fdcFood.gtinUpc,
        productName: fdcFood.description,
        brands: fdcFood.brandName,
        url: FDCConst.getFoodDetailUrlString(fdcId),
        productQuantity: fdcFood.packageWeight,
        productUnit: fdcFood.servingSizeUnit,
        servingQuantity: fdcFood.servingSize,
        servingUnit: fdcFood.servingSizeUnit,
        nutriments:
            ProductNutrimentsEntity.fromFDCNutriments(fdcFood.foodNutrients),
        source: ProductSourceEntity.fdc);
  }

  /// Value returned from OFF can either be String, int or double.
  /// Try casting it to a double value for calculation
  static double? _tryQuantityCast(dynamic value) {
    double? parsedValue;

    if (value == null) {
      parsedValue = null;
    } else if (value is double) {
      parsedValue = value;
    } else if (value is int) {
      parsedValue = value.toDouble();
    } else if (value is String) {
      value.replaceAll(RegExp("mg|g|kg|ml|cl|l| "), ""); // TODO extract
      final doubleParsed =
          double.tryParse(value) ?? int.tryParse(value)?.toDouble();
      parsedValue = doubleParsed;
    }
    return parsedValue;
  }

  /// TODO extract correct unit
  /// Unit can either be 100g or 100ml
  static String? _tryGetUnit(String? quantityString) {
    if (quantityString == null) return null;

    final isLiter = quantityString.toUpperCase().contains("L");

    if (isLiter) {
      return "ml";
    } else {
      return "g";
    }
  }

  @override
  List<Object?> get props => [code, productName];
}

enum ProductSourceEntity {
  unknown,
  off,
  fdc;

  factory ProductSourceEntity.fromProductSourceDBO(
      ProductSourceDBO productSourceDBO) {
    ProductSourceEntity productSourceEntity;
    switch (productSourceDBO) {
      case ProductSourceDBO.unknown:
        productSourceEntity = ProductSourceEntity.unknown;
        break;
      case ProductSourceDBO.off:
        productSourceEntity = ProductSourceEntity.off;
        break;
      case ProductSourceDBO.fdc:
        productSourceEntity = ProductSourceEntity.fdc;
        break;
    }
    return productSourceEntity;
  }
}
