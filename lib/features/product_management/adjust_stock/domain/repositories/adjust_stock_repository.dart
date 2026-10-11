import '../../../../../core/errors/result.dart';

typedef StockItem = ({int productId, String barcode, String description, int stock});

/// `stockAdjustment.adjustmentType` values.
enum StockReason {
  stockIn('Stock In'),
  stockOut('Stock Out');

  const StockReason(this.label);
  final String label;
}

abstract interface class AdjustStockRepository {
  /// Matches the barcode exactly, else the description.
  Future<Result<StockItem?>> find(String query);

  /// Updates the stock and writes the adjustment log in one transaction.
  Future<Result<int>> adjust(StockItem item, {required StockReason reason, required int quantity});
}
