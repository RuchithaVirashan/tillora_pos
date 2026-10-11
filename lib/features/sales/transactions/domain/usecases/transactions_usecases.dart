import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/session/user_session.dart';
import '../entities/shift_transaction.dart';
import '../repositories/transactions_repository.dart';

class GetShiftTransactions {
  const GetShiftTransactions(this._repository);
  final TransactionsRepository _repository;

  Future<Result<List<ShiftTransaction>>> call(int logId) => _repository.forShift(logId);
}

class GetTransactionLines {
  const GetTransactionLines(this._repository);
  final TransactionsRepository _repository;

  Future<Result<List<TransactionLine>>> call(int transactionId) => _repository.lines(transactionId);
}

class GetPayTypeOptions {
  const GetPayTypeOptions(this._repository);
  final TransactionsRepository _repository;

  Future<Result<List<PayTypeOption>>> call() => _repository.payTypes();
}

/// Corrects the pay type of a single-method transaction.
class SwapPayType {
  const SwapPayType(this._repository);
  final TransactionsRepository _repository;

  static const accessFlag = 'swapPayTypeAccess';

  Future<Result<void>> call(UserSession session, ShiftTransaction tx, PayTypeOption to) async {
    if (!session.access.can(accessFlag)) return const Err(PermissionFailure('You do not have swap pay type access'));
    if (tx.isPartPay) return const Err(ValidationFailure('Part-paid transactions cannot be swapped'));
    if (tx.method == to.name) return const Err(ValidationFailure('That is already the pay type'));
    return _repository.changePayType(tx.id, to);
  }
}
