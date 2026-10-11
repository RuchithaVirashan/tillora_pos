import '../../../../../core/errors/result.dart';
import '../entities/sellable_item.dart';
import '../repositories/sales_repository.dart';

class RecordAgeRefusal {
  const RecordAgeRefusal(this._repository);

  final SalesRepository _repository;

  Future<Result<void>> call(SellableItem item, {required int logId}) => _repository.recordAgeRefusal(item, logId: logId);
}
