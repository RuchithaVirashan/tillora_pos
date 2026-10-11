import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../repositories/payment_type_admin_repository.dart';

class GetManagedPaymentTypes {
  const GetManagedPaymentTypes(this._repository);
  final PaymentTypeAdminRepository _repository;

  Future<Result<List<ManagedPaymentType>>> call() => _repository.paymentTypes();
}

/// Adds ([existing] null) or updates a payment type.
class SavePaymentType {
  const SavePaymentType(this._repository);
  final PaymentTypeAdminRepository _repository;

  /// Names the till uses for its own payment methods.
  static const reserved = {'cash', 'card', 'partpay'};

  Future<Result<int>> call({
    required ManagedPaymentType? existing,
    required String name,
    required bool enabled,
    required List<ManagedPaymentType> all,
  }) async {
    final value = name.trim();
    if (value.isEmpty) return const Err(ValidationFailure('Enter the payment type name'));
    if (reserved.contains(value.toLowerCase())) return Err(ValidationFailure('$value is a built-in payment method'));
    if (all.any((t) => t.id != existing?.id && t.name.toLowerCase() == value.toLowerCase())) {
      return Err(ValidationFailure('$value already exists'));
    }
    if (existing == null) return _repository.add(value, enabled: enabled);
    return switch (await _repository.update(existing.id, value, enabled: enabled)) {
      Ok() => Ok(existing.id),
      Err(:final failure) => Err(failure),
    };
  }
}

/// A type used on past sales stays, so reports can still name it;
/// disable it instead.
class DeletePaymentType {
  const DeletePaymentType(this._repository);
  final PaymentTypeAdminRepository _repository;

  Future<Result<void>> call(ManagedPaymentType type) async {
    switch (await _repository.usageCount(type.id)) {
      case Ok(value: final n) when n > 0:
        return Err(ValidationFailure('${type.name} was used on $n ${n == 1 ? 'sale' : 'sales'}. Disable it instead of deleting.'));
      case Err(:final failure):
        return Err(failure);
      case Ok():
        return _repository.delete(type.id);
    }
  }
}
