import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/session/access_rights.dart';
import '../../../../../core/session/user_session.dart';
import '../entities/price_check_item.dart';
import '../repositories/price_check_repository.dart';

class SearchProducts {
  const SearchProducts(this._repository);
  final PriceCheckRepository _repository;

  Future<Result<List<PriceCheckItem>>> call(String query) async {
    if (query.trim().isEmpty) return const Err(ValidationFailure('Enter a barcode, PLU code or description'));
    return _repository.search(query);
  }
}

class UpdatePrice {
  const UpdatePrice(this._repository);
  final PriceCheckRepository _repository;

  Future<Result<void>> call(UserSession session, PriceCheckItem item, int newPriceCents) async {
    if (!session.access.can(AccessRights.priceUpdate)) return const Err(PermissionFailure('You do not have price update access'));
    if (newPriceCents <= 0) return const Err(ValidationFailure('Enter a new price'));
    if (newPriceCents == item.priceCents) return const Err(ValidationFailure('The new price is the same as the current price'));
    return _repository.updatePrice(item.productId, newPriceCents);
  }
}

class SetExpiry {
  const SetExpiry(this._repository);
  final PriceCheckRepository _repository;

  Future<Result<void>> call(PriceCheckItem item, DateTime? date) => _repository.setExpiry(item.productId, date);
}
