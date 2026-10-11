import '../../../../../core/errors/result.dart';
import '../entities/department.dart';

abstract interface class DepartmentRepository {
  /// By id, each with its sub-departments.
  Future<Result<List<Department>>> departments();

  Future<Result<bool>> idExists(int id);

  /// Inserts when [Department.id] is new, else updates. Returns the id.
  Future<Result<int>> save(Department department, {required bool isNew});

  /// Products using the department.
  Future<Result<int>> usageCount(int id);

  Future<Result<void>> delete(int id);

  Future<Result<void>> addSubDepartment(int departmentId, String name);

  Future<Result<void>> deleteSubDepartment(int subDepartmentId);
}
