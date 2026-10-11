import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

class GetSuppliers {
  const GetSuppliers(this._repository);
  final SupplierRepository _repository;

  Future<Result<List<Supplier>>> call() => _repository.suppliers();
}

/// Adds a new supplier ([Supplier.id] null) or updates an existing one.
class SaveSupplier {
  const SaveSupplier(this._repository);
  final SupplierRepository _repository;

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phone = RegExp(r'^\+?[0-9 ]{9,16}$');

  Future<Result<int>> call(Supplier supplier) async {
    final s = Supplier(
      id: supplier.id,
      name: supplier.name.trim(),
      address: SupplierAddress(
        number: supplier.address.number.trim(),
        street: supplier.address.street.trim(),
        district: supplier.address.district.trim(),
        country: supplier.address.country.trim(),
      ),
      phone: supplier.phone.trim(),
      email: supplier.email.trim(),
    );
    if (s.name.isEmpty || s.address.number.isEmpty || s.address.street.isEmpty || s.phone.isEmpty || s.email.isEmpty) {
      return const Err(ValidationFailure('Please fill the field'));
    }
    if (s.address.district.isEmpty) return const Err(ValidationFailure('Please select address district'));
    if (!_phone.hasMatch(s.phone)) return const Err(ValidationFailure('Please enter a valid phone number (+94 11 1234567)'));
    if (!_email.hasMatch(s.email)) return const Err(ValidationFailure('Please enter a correct email address'));

    final id = s.id;
    if (id == null) return _repository.add(s);
    return switch (await _repository.update(s)) {
      Ok() => Ok(id),
      Err(:final failure) => Err(failure),
    };
  }
}

class DeleteSupplier {
  const DeleteSupplier(this._repository);
  final SupplierRepository _repository;

  Future<Result<void>> call(int id) => _repository.delete(id);
}
