import '../../../../../core/errors/result.dart';
import '../repositories/payout_repository.dart';

class GetPayoutReasons {
  const GetPayoutReasons(this._repository);
  final PayoutRepository _repository;

  Future<Result<List<String>>> call() => _repository.reasons();
}
