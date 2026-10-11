import '../../../../../core/catalog/department_option.dart';
import '../../../../../core/errors/result.dart';

/// A product sold by weight; [pricePerKgCents] is the kg price.
typedef WeightProduct = ({String code, String description, int pricePerKgCents, String departmentName});

abstract interface class WeightItemsRepository {
  Future<Result<List<WeightProduct>>> products();
  Future<Result<List<DepartmentOption>>> departments();
  Future<Result<bool>> codeExists(String code);
  Future<Result<void>> add({
    required String code,
    required String description,
    required int pricePerKgCents,
    required DepartmentOption department,
    required int ageLimit,
  });
}
