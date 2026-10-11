import '../../../../../core/catalog/department_option.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/validators.dart';
import '../repositories/weight_items_repository.dart';

class GetWeightProducts {
  const GetWeightProducts(this._repository);
  final WeightItemsRepository _repository;

  Future<Result<List<WeightProduct>>> call() => _repository.products();
}

class GetWeightDepartments {
  const GetWeightDepartments(this._repository);
  final WeightItemsRepository _repository;

  Future<Result<List<DepartmentOption>>> call() => _repository.departments();
}

class AddWeightProduct {
  const AddWeightProduct(this._repository);
  final WeightItemsRepository _repository;

  Future<Result<void>> call({
    required String code,
    required String description,
    required int pricePerKgCents,
    required DepartmentOption? department,
    required bool ageRestricted,
  }) async {
    if (Validators.barcode(code.trim()) case final error?) return Err(ValidationFailure(error));
    if (description.trim().isEmpty) return const Err(ValidationFailure('Enter a description'));
    if (pricePerKgCents <= 0) return const Err(ValidationFailure('Enter the price per kg'));
    if (department == null) return const Err(ValidationFailure('Select a department'));
    if (await _repository.codeExists(code.trim()) case Ok(value: true)) {
      return Err(ValidationFailure('Code ${code.trim()} is already used'));
    }
    return _repository.add(
      code: code.trim(),
      description: description.trim(),
      pricePerKgCents: pricePerKgCents,
      department: department,
      ageLimit: ageRestricted ? (department.ageLimit > 0 ? department.ageLimit : 18) : 0,
    );
  }
}
