import '../../../../../core/errors/result.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/sellable_item.dart';
import '../repositories/sales_repository.dart';

/// Quick items for the 2×5 grid on the sales screen.
class GetQuickItems implements UseCase<List<SellableItem>, NoParams> {
  const GetQuickItems(this._repository);

  final SalesRepository _repository;

  @override
  Future<Result<List<SellableItem>>> call(NoParams params) => _repository.quickItems();
}
