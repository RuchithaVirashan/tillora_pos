import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../entities/sellable_item.dart';
import '../repositories/sales_repository.dart';

class GetWeighedProducts {
  const GetWeighedProducts(this._repository);
  final SalesRepository _repository;

  Future<Result<List<SellableItem>>> call(String query) => _repository.weighedProducts(query);
}

/// Turns a per-kg product and a weight into one cart item priced for that
/// weight, e.g. "Carrots 250g" at a quarter of the kg price.
class WeighItem {
  const WeighItem();

  Result<SellableItem> call(SellableItem perKg, {required int grams}) {
    if (grams <= 0) return const Err(ValidationFailure('Enter the weight in grams'));
    final cents = (perKg.priceCents * grams / 1000).round();
    if (cents <= 0) return const Err(ValidationFailure('That weight is too small to charge for'));
    return Ok(SellableItem(
      productId: perKg.productId,
      description: '${perKg.description} ${grams}g',
      barcode: perKg.barcode,
      priceCents: cents,
      departmentId: perKg.departmentId,
      departmentName: perKg.departmentName,
      vat: perKg.vat,
      ageLimit: perKg.ageLimit,
      source: ItemSource.weighed,
    ));
  }

  /// Grams that a [priceCents] amount buys, for entering by price.
  static int gramsFor(SellableItem perKg, int priceCents) =>
      perKg.priceCents <= 0 ? 0 : (priceCents * 1000 / perKg.priceCents).round();
}
