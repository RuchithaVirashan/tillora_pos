import '../../../../../core/errors/result.dart';
import '../entities/active_promotion.dart';
import '../repositories/sales_repository.dart';

class GetActivePromotions {
  const GetActivePromotions(this._repository);
  final SalesRepository _repository;

  Future<Result<List<ActivePromotion>>> call(DateTime day) => _repository.activePromotions(day);
}
