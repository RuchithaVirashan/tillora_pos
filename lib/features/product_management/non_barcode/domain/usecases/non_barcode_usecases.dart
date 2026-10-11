import '../../../../../core/catalog/department_option.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../entities/non_barcode_item.dart';
import '../repositories/non_barcode_repository.dart';

class GetNonBarcodeItems {
  const GetNonBarcodeItems(this._repository);
  final NonBarcodeRepository _repository;

  Future<Result<List<NonBarcodeItem>>> call() => _repository.items();
}

/// Departments for the form and the next free ID.
class GetNonBarcodeSetup {
  const GetNonBarcodeSetup(this._repository);
  final NonBarcodeRepository _repository;

  Future<Result<(List<DepartmentOption>, int)>> call() async {
    final departments = await _repository.departments();
    final next = await _repository.nextItemId();
    return switch ((departments, next)) {
      (Ok(value: final d), Ok(value: final n)) => Ok((d, n)),
      (Err(:final failure), _) || (_, Err(:final failure)) => Err(failure),
    };
  }
}

class AddNonBarcodeItem {
  const AddNonBarcodeItem(this._repository);
  final NonBarcodeRepository _repository;

  Future<Result<void>> call({
    required int? itemId,
    required String description,
    required int priceCents,
    required DepartmentOption? department,
    required bool ageRestricted,
  }) async {
    if (itemId == null || itemId <= 0) return const Err(ValidationFailure('Enter a numeric ID'));
    if (description.trim().isEmpty) return const Err(ValidationFailure('Enter a description'));
    if (department == null) return const Err(ValidationFailure('Select a department'));
    if (priceCents < 0) return const Err(ValidationFailure('Price cannot be negative'));
    if (await _repository.idExists(itemId) case Ok(value: true)) {
      return Err(ValidationFailure('ID $itemId is already used'));
    }
    return _repository.add(
      NonBarcodeItem(
        itemId: itemId,
        description: description.trim(),
        priceCents: priceCents,
        departmentId: department.id,
        ageLimit: ageRestricted ? (department.ageLimit > 0 ? department.ageLimit : 18) : 0,
      ),
      vat: department.vat,
    );
  }
}

class DeleteNonBarcodeItem {
  const DeleteNonBarcodeItem(this._repository);
  final NonBarcodeRepository _repository;

  Future<Result<void>> call(int itemId) => _repository.delete(itemId);
}
