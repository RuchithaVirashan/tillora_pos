import '../../../../../core/errors/result.dart';
import '../entities/price_check_item.dart';

abstract interface class PriceCheckRepository {
  Future<Result<List<PriceCheckItem>>> search(String query);
  Future<Result<void>> updatePrice(int productId, int priceCents);
  Future<Result<void>> setExpiry(int productId, DateTime? date);
}
