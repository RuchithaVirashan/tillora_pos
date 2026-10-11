import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../entities/department.dart';
import '../repositories/department_repository.dart';

class GetDepartments {
  const GetDepartments(this._repository);
  final DepartmentRepository _repository;

  Future<Result<List<Department>>> call() => _repository.departments();
}

class SaveDepartment {
  const SaveDepartment(this._repository);
  final DepartmentRepository _repository;

  /// [isNew] adds a department; otherwise [department] is updated.
  Future<Result<int>> call(Department department, {required bool isNew}) async {
    final name = department.name.trim();
    if (name.isEmpty) return const Err(ValidationFailure('Enter the department name'));
    if (department.vat < 0 || department.vat > 100) return const Err(ValidationFailure('VAT must be between 0 and 100%'));
    if (department.ageLimit < 0 || department.ageLimit > 99) return const Err(ValidationFailure('Enter an age between 1 and 99'));
    if (department.groupId <= 0) return const Err(ValidationFailure('Group ID must be a positive number'));
    final id = department.id;
    if (isNew && id != null) {
      if (id <= 0) return const Err(ValidationFailure('Department ID must be a positive number'));
      if (await _repository.idExists(id) case Ok(value: true)) return Err(ValidationFailure('Department ID $id is already used'));
    }
    return _repository.save(
      Department(
        id: id,
        name: name,
        vat: department.vat,
        ageLimit: department.ageLimit,
        groupId: department.groupId,
        quickMenu: department.quickMenu,
      ),
      isNew: isNew,
    );
  }
}

/// A department in use by products cannot be deleted.
class DeleteDepartment {
  const DeleteDepartment(this._repository);
  final DepartmentRepository _repository;

  Future<Result<void>> call(Department department) async {
    final id = department.id!;
    switch (await _repository.usageCount(id)) {
      case Ok(value: final n) when n > 0:
        return Err(ValidationFailure('${department.name} is used by $n products; move them to another department first'));
      case Err(:final failure):
        return Err(failure);
      case Ok():
        return _repository.delete(id);
    }
  }
}

class AddSubDepartment {
  const AddSubDepartment(this._repository);
  final DepartmentRepository _repository;

  Future<Result<void>> call(Department department, String name) async {
    final value = name.trim();
    if (value.isEmpty) return const Err(ValidationFailure('Enter the sub department name'));
    if (department.subDepartments.any((s) => s.name.toLowerCase() == value.toLowerCase())) {
      return Err(ValidationFailure('$value already exists in ${department.name}'));
    }
    return _repository.addSubDepartment(department.id!, value);
  }
}

class DeleteSubDepartment {
  const DeleteSubDepartment(this._repository);
  final DepartmentRepository _repository;

  Future<Result<void>> call(SubDepartment sub) => _repository.deleteSubDepartment(sub.id);
}
