import 'package:opennutritracker/core/data/dbo/product_dbo.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off_product.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/product_nutriments_entity.dart';

class ProductEntity {
  final String? code;
  final String? productName;
  final String? productNameEN;
  final String? productNameDE;

  final String? brands;

  final String? thumbnailImageUrl;
  final String? mainImageUrl;

  final String? url;

  final double? productQuantity;
  final String? productUnit;
  final double? servingQuantity;
  final String? servingUnit;

  final ProductNutrimentsEntity nutriments;

  String? get productQuantityFormatted => productQuantity?.floor().toString();

  ProductEntity(
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
      required this.nutriments});

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
          productDBO.nutriments));

  factory ProductEntity.fromOFFProduct(OFFProduct offProduct) {
    return ProductEntity(
        code: offProduct.code,
        productName: offProduct.product_name,
        productNameEN: offProduct.product_name_en,
        productNameDE: offProduct.product_name_de,
        brands: offProduct.brands,
        thumbnailImageUrl: offProduct.image_front_thumb_url,
        mainImageUrl: offProduct.image_front_url,
        url: offProduct.url,
        productQuantity: _tryQuantityCast(offProduct.product_quantity),
        productUnit: _tryGetUnit(offProduct.quantity),
        servingQuantity: _tryQuantityCast(offProduct.serving_quantity),
        servingUnit: _tryGetUnit(offProduct.quantity),
        nutriments:
            ProductNutrimentsEntity.fromOffNutriments(offProduct.nutriments));
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

  static String? _tryGetUnit(String? quantityString) {
    if (quantityString == null) return null;

    // TODO extract unit
    return "g";
  }
}
