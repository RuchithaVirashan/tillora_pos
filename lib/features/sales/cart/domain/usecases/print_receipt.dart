import '../../../../../core/errors/result.dart';
import '../repositories/sales_repository.dart';

class PrintReceipt {
  const PrintReceipt(this._repository);

  final SalesRepository _repository;

  Future<Result<void>> call(int transactionId, {bool reprint = false}) =>
      _repository.printReceipt(transactionId, reprint: reprint);
}
