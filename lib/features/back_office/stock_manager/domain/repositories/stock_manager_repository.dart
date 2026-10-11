import '../../../../../core/errors/result.dart';
import '../entities/stock_entry.dart';

abstract interface class StockManagerRepository {
  /// Barcode products A–Z, filtered by [query] (barcode or description)
  /// and [departmentId]. At most [limit] entries are returned, but the
  /// count and gross total cover every match.
  Future<Result<StockList>> stock({required String query, int? departmentId, int limit});

  /// Adds [delta] (negative to remove) and logs it in one transaction.
  /// Returns the new stock level.
  Future<Result<int>> adjust(StockEntry entry, {required StockAdjustReason reason, required int delta});
}
