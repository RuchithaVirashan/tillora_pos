import '../../../../../core/errors/result.dart';

typedef ManagedPaymentType = ({int id, String name, bool enabled});

abstract interface class PaymentTypeAdminRepository {
  Future<Result<List<ManagedPaymentType>>> paymentTypes();
  Future<Result<int>> add(String name, {required bool enabled});
  Future<Result<void>> update(int id, String name, {required bool enabled});

  /// Sales that were paid (partly) with this type.
  Future<Result<int>> usageCount(int id);
  Future<Result<void>> delete(int id);
}
