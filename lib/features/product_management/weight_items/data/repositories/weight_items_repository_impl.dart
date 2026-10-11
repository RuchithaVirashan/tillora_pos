import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/catalog/department_option.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../infrastructure/database/dao/products_dao.dart';
import '../../domain/repositories/weight_items_repository.dart';

class WeightItemsRepositoryImpl implements WeightItemsRepository {
  WeightItemsRepositoryImpl(this._db, this._products);

  final Database _db;
  final ProductsDao _products;

  @override
  Future<Result<List<WeightProduct>>> products() => _guard(() async {
    final departments = {for (final r in await _products.departments()) r['id'] as int: r['name'] as String};
    final rows = await _products.weighedProducts('', limit: 500);
    return [
      for (final r in rows)
        (
          code: r['barcode'] as String,
          description: r['description'] as String,
          pricePerKgCents: Money.toCents(r['price'] as num),
          departmentName: departments[r['departmentId']] ?? '',
        ),
    ];
  });

  @override
  Future<Result<List<DepartmentOption>>> departments() =>
      _guard(() async => [for (final r in await _products.departments()) DepartmentOption.fromRow(r)]);

  @override
  Future<Result<bool>> codeExists(String code) => _guard(() async {
    final rows = await _db.rawQuery('SELECT 1 FROM products WHERE barcode = ? COLLATE NOCASE LIMIT 1', [code]);
    return rows.isNotEmpty;
  });

  @override
  Future<Result<void>> add({
    required String code,
    required String description,
    required int pricePerKgCents,
    required DepartmentOption department,
    required int ageLimit,
  }) => _guard(
    () => _db.insert('products', {
      'description': description,
      'barcode': code,
      'price': Money.fromCents(pricePerKgCents),
      'departmentId': department.id,
      'stock': 0,
      'vat': department.vat,
      'caseBarcode': 'weight',
      'isQuickitem': 0,
      'ageRefusal': ageLimit,
    }),
  );

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }
}
