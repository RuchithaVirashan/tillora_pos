import '../../../../../core/errors/result.dart';
import '../entities/payment_type.dart';

abstract interface class PaymentTypeRepository {
  Future<Result<List<PaymentType>>> enabledTypes();
}
