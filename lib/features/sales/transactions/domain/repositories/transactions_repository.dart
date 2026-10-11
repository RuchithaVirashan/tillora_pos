import '../../../../../core/errors/result.dart';
import '../entities/shift_transaction.dart';

abstract interface class TransactionsRepository {
  /// Newest first.
  Future<Result<List<ShiftTransaction>>> forShift(int logId);

  Future<Result<List<TransactionLine>>> lines(int transactionId);

  /// Cash, Card and the enabled payment types.
  Future<Result<List<PayTypeOption>>> payTypes();

  Future<Result<void>> changePayType(int transactionId, PayTypeOption to);
}
