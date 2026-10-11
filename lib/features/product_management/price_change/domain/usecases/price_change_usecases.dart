import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../repositories/price_change_repository.dart';

class FindPricedProduct {
  const FindPricedProduct(this._repository);
  final PriceChangeRepository _repository;

  Future<Result<PricedProduct>> call(String query) async {
    if (query.trim().isEmpty) return const Err(ValidationFailure('Scan or type a barcode'));
    return switch (await _repository.find(query.trim())) {
      Ok(value: final p?) => Ok(p),
      Ok() => Err(ValidationFailure('No product found for ${query.trim()}')),
      Err(:final failure) => Err(failure),
    };
  }
}

class ChangePrice {
  const ChangePrice(this._repository);
  final PriceChangeRepository _repository;

  Future<Result<void>> call(PricedProduct product, int newPriceCents) async {
    if (newPriceCents <= 0) return const Err(ValidationFailure('Enter a new price'));
    if (newPriceCents == product.priceCents) return const Err(ValidationFailure('The new price is the same as the current price'));
    return _repository.updatePrice(product.productId, newPriceCents);
  }
}

class SetProductExpiry {
  const SetProductExpiry(this._repository);
  final PriceChangeRepository _repository;

  Future<Result<void>> call(PricedProduct product, DateTime? date) => _repository.setExpiry(product.productId, date);
}
