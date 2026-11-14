class ProductNotFoundException implements Exception {}

/// Not among the user's own foods, and Open Food Facts — the only other
/// place a barcode is looked up — is switched off in Settings → Food
/// databases (#946). Still a [ProductNotFoundException], so a caller that
/// only knows "not found" keeps treating it as one.
class OffDisabledException extends ProductNotFoundException {}
