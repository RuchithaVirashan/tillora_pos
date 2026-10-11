import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../cart/domain/entities/cart.dart';
import '../entities/held_sale.dart';
import '../repositories/hold_repository.dart';

class GetHeldSales {
  const GetHeldSales(this._repository);
  final HoldRepository _repository;

  Future<Result<List<HeldSale>>> call(int logId) => _repository.heldSales(logId);
}

class HoldSale {
  const HoldSale(this._repository);
  final HoldRepository _repository;

  Future<Result<void>> call(Cart cart, {required int logId}) {
    if (cart.isEmpty) return Future.value(const Err(ValidationFailure('There is nothing to hold')));
    if (cart.tenders.isNotEmpty) return Future.value(const Err(ValidationFailure('A part-paid sale cannot be held')));
    if (cart.refund) return Future.value(const Err(ValidationFailure('Refunds cannot be held')));
    return _repository.hold(cart.lines, logId: logId);
  }
}

class RecallSale {
  const RecallSale(this._repository);
  final HoldRepository _repository;

  /// [holdId] null recalls every hold for the shift.
  Future<Result<List<CartLine>>> call({int? holdId, required int logId}) =>
      holdId == null ? _repository.recallAll(logId) : _repository.recall(holdId);
}
