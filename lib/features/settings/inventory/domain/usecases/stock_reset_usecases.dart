import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../repositories/stock_reset_repository.dart';

class GetStockSummary {
  const GetStockSummary(this._repository);
  final StockResetRepository _repository;

  Future<Result<StockSummary>> call() => _repository.summary();
}

class ResetStock {
  const ResetStock(this._repository);
  final StockResetRepository _repository;

  Future<Result<int>> call(StockSummary current) async {
    if (current.products == 0) return const Err(ValidationFailure('Every product is already at zero stock'));
    return _repository.reset();
  }
}
