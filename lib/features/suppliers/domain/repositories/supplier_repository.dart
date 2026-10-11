import '../../../../core/errors/result.dart';
import '../entities/supplier.dart';

abstract interface class SupplierRepository {
  /// A–Z by name.
  Future<Result<List<Supplier>>> suppliers();
  Future<Result<int>> add(Supplier supplier);
  Future<Result<void>> update(Supplier supplier);
  Future<Result<void>> delete(int id);
}
