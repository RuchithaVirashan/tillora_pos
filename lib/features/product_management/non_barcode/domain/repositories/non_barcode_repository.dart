import '../../../../../core/catalog/department_option.dart';
import '../../../../../core/errors/result.dart';
import '../entities/non_barcode_item.dart';

abstract interface class NonBarcodeRepository {
  Future<Result<List<NonBarcodeItem>>> items();
  Future<Result<List<DepartmentOption>>> departments();
  Future<Result<int>> nextItemId();
  Future<Result<bool>> idExists(int itemId);
  Future<Result<void>> add(NonBarcodeItem item, {required double vat});
  Future<Result<void>> delete(int itemId);
}
