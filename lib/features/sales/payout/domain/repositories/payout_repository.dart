import '../../../../../core/errors/result.dart';

abstract interface class PayoutRepository {
  /// Payout reasons set in Product Management › Manage Payout Products.
  Future<Result<List<String>>> reasons();
}
