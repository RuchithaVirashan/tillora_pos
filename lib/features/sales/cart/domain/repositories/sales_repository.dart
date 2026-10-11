import '../../../../../core/errors/result.dart';
import '../entities/cart.dart';
import '../entities/sellable_item.dart';

abstract interface class SalesRepository {
  /// Null value when nothing matches the code.
  Future<Result<SellableItem?>> findByBarcode(String barcode);

  Future<Result<List<SellableItem>>> quickItems();

  /// Writes the transaction, its lines and the sold-item log, and adjusts
  /// stock, all in one database transaction. Returns the transaction id.
  Future<Result<int>> saveSale(Cart cart, {required int logId});

  Future<Result<void>> openCashDrawer();

  /// Logs a refused age-restricted sale to `posRecords`.
  Future<Result<void>> recordAgeRefusal(SellableItem item, {required int logId});
}
