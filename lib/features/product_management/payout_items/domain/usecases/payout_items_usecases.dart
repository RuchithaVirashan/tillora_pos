import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../repositories/payout_items_repository.dart';

class GetPayoutItems {
  const GetPayoutItems(this._repository);
  final PayoutItemsRepository _repository;

  Future<Result<List<PayoutItem>>> call() => _repository.items();
}

class AddPayoutItem {
  const AddPayoutItem(this._repository);
  final PayoutItemsRepository _repository;

  Future<Result<void>> call(String name, {required List<PayoutItem> existing}) async {
    final value = name.trim();
    if (value.isEmpty) return const Err(ValidationFailure('Enter a payout name'));
    if (existing.any((p) => p.name.toLowerCase() == value.toLowerCase())) {
      return Err(ValidationFailure('$value already exists'));
    }
    return _repository.add(value);
  }
}

class DeletePayoutItem {
  const DeletePayoutItem(this._repository);
  final PayoutItemsRepository _repository;

  Future<Result<void>> call(int id) => _repository.delete(id);
}
