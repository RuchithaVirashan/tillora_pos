import '../../../../../core/errors/result.dart';

/// Products whose stock is not zero, and their units.
typedef StockSummary = ({int products, int units});

abstract interface class StockResetRepository {
  Future<Result<StockSummary>> summary();

  /// Sets every product's stock to zero and logs each change as a
  /// 'Stock Reset' adjustment. Returns how many products changed.
  Future<Result<int>> reset();
}
