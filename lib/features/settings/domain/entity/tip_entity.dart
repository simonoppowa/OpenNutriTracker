import 'package:equatable/equatable.dart';

/// The three tips the Support page offers (#1534). Each is a consumable
/// in-app product that unlocks nothing.
///
/// The product IDs are the same on both stores and can never be reused once
/// created, even after deletion, so they are fixed here once.
enum TipSize {
  small('tip_small'),
  medium('tip_medium'),
  large('tip_large');

  const TipSize(this.productId);

  final String productId;

  static final Set<String> productIds = {
    for (final size in values) size.productId,
  };

  static TipSize? fromProductId(String productId) {
    for (final size in values) {
      if (size.productId == productId) return size;
    }
    return null;
  }
}

/// A tip the store returned, with its store-formatted [price]. The app never
/// shows a hard-coded amount: other storefronts use the store's own prices.
class TipEntity extends Equatable {
  final TipSize size;

  /// The price exactly as the store formatted it, e.g. "€1.99".
  final String price;

  /// Only for ordering the tips; never shown.
  final double rawPrice;

  const TipEntity({
    required this.size,
    required this.price,
    required this.rawPrice,
  });

  @override
  List<Object?> get props => [size, price, rawPrice];
}
