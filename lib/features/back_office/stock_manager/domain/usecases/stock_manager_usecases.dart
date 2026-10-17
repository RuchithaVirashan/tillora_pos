import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../entities/stock_entry.dart';
import '../repositories/stock_manager_repository.dart';

class GetStock {
  const GetStock(this._repository);
  final StockManagerRepository _repository;

  Future<Result<StockList>> call({String query = '', int? departmentId}) =>
      _repository.stock(query: query.trim(), departmentId: departmentId, limit: 1000);
}

class AdjustProductStock {
  const AdjustProductStock(this._repository);
  final StockManagerRepository _repository;

  Future<Result<int>> call(StockEntry entry, {required StockAdjustReason reason, required int delta}) async {
    if (delta == 0) return const Err(ValidationFailure('Enter a quantity'));
    if (reason.sign > 0 && delta < 0) return Err(ValidationFailure('${reason.label} can only add stock'));
    if (reason.sign < 0 && delta > 0) return Err(ValidationFailure('${reason.label} can only remove stock'));
    if (reason.sign < 0 && entry.stock + delta < 0) {
      return Err(ValidationFailure('Only ${entry.stock < 0 ? 0 : entry.stock} in stock'));
    }
    return _repository.adjust(entry, reason: reason, delta: delta);
  }
}
