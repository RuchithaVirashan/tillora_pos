import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../repositories/adjust_stock_repository.dart';

class FindStockItem {
  const FindStockItem(this._repository);
  final AdjustStockRepository _repository;

  Future<Result<StockItem>> call(String query) async {
    if (query.trim().isEmpty) return const Err(ValidationFailure('Please scan barcode and tap Find to load data'));
    return switch (await _repository.find(query.trim())) {
      Ok(value: final item?) => Ok(item),
      Ok() => Err(ValidationFailure('No product found for ${query.trim()}')),
      Err(:final failure) => Err(failure),
    };
  }
}

/// Returns the new stock level.
class AdjustStock {
  const AdjustStock(this._repository);
  final AdjustStockRepository _repository;

  static int newStock(StockItem item, StockReason reason, int quantity) =>
      reason == StockReason.stockIn ? item.stock + quantity : item.stock - quantity;

  Future<Result<int>> call(StockItem item, {required StockReason reason, required int quantity}) async {
    if (quantity <= 0) return const Err(ValidationFailure('Enter a quantity above 0'));
    return _repository.adjust(item, reason: reason, quantity: quantity);
  }
}
