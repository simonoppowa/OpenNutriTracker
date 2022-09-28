import 'package:opennutritracker/features/addItem/data/dto/off_product.dart';

class ProductEntity {
  final String? code;
  final String? productName;
  final String? productNameEN;
  final String? productNameDE;

  final String? brands;

  final String? thumbnailImageUrl;
  final String? mainImageUrl;

  final double? productQuantity;
  final double? servingQuantity;

  String? get productQuantityFormatted => productQuantity?.floor().toString();

  ProductEntity(
      {required this.code,
      required this.productName,
      required this.productNameEN,
      required this.productNameDE,
      required this.brands,
      required this.thumbnailImageUrl,
      required this.mainImageUrl,
      required this.productQuantity,
      required this.servingQuantity});

  factory ProductEntity.fromOFFProduct(OFFProduct offProduct) {
    return ProductEntity(
        code: offProduct.code,
        productName: offProduct.product_name,
        productNameEN: offProduct.product_name_en,
        productNameDE: offProduct.product_name_de,
        brands: offProduct.brands,
        thumbnailImageUrl: offProduct.image_front_thumb_url,
        mainImageUrl: offProduct.image_front_url,
        productQuantity: _tryQuantityCast(offProduct.product_quantity),
        servingQuantity: _tryQuantityCast(offProduct.serving_quantity));
  }

  /// Value returned from OFF can either be String, int or double.
  /// Try casting it to a double value for calculation
  static double? _tryQuantityCast<T>(dynamic value) {
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
}
