import '../../../../../core/errors/result.dart';

abstract interface class CashLiftRepository {
  /// Records the lift for the shift and opens the cash drawer.
  Future<Result<void>> liftCash({required int logId, required int amountCents});
}
