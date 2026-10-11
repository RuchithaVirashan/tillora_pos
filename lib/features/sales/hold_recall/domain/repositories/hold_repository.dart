import '../../../../../core/errors/result.dart';
import '../../../cart/domain/entities/cart.dart';
import '../entities/held_sale.dart';

abstract interface class HoldRepository {
  Future<Result<List<HeldSale>>> heldSales(int logId);

  Future<Result<void>> hold(List<CartLine> lines, {required int logId});

  /// Returns the held lines and deletes the hold, in one transaction.
  Future<Result<List<CartLine>>> recall(int holdId);

  /// Every hold for the shift, merged, oldest first.
  Future<Result<List<CartLine>>> recallAll(int logId);
}
