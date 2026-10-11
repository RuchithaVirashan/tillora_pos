import '../../../../../core/errors/result.dart';
import '../repositories/expired_items_repository.dart';

/// Expired on or before [before]; with no date, everything expired by today.
class GetExpiredItems {
  const GetExpiredItems(this._repository);
  final ExpiredItemsRepository _repository;

  Future<Result<List<ExpiredProduct>>> call({DateTime? before}) => _repository.expired(before ?? DateTime.now());
}
