import '../../../../../core/errors/result.dart';

typedef PricedProduct = ({int productId, String barcode, String description, int priceCents, DateTime? expiryDate});

abstract interface class PriceChangeRepository {
  Future<Result<PricedProduct?>> find(String query);
  Future<Result<void>> updatePrice(int productId, int priceCents);
  Future<Result<void>> setExpiry(int productId, DateTime? date);
}
