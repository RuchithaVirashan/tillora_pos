import '../../../../../core/errors/result.dart';
import '../entities/payment_type.dart';
import '../repositories/payment_type_repository.dart';

class GetPaymentTypes {
  const GetPaymentTypes(this._repository);
  final PaymentTypeRepository _repository;

  Future<Result<List<PaymentType>>> call() => _repository.enabledTypes();
}
