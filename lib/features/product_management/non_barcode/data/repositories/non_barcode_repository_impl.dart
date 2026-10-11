import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/catalog/department_option.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../infrastructure/database/dao/products_dao.dart';
import '../../domain/entities/non_barcode_item.dart';
import '../../domain/repositories/non_barcode_repository.dart';

class NonBarcodeRepositoryImpl implements NonBarcodeRepository {
  NonBarcodeRepositoryImpl(this._db, this._products);

  final Database _db;
  final ProductsDao _products;

  /// Reserved for the item and sale discount lines.
  static const _reserved = [888888, 999999];
  static const _firstId = 300000;

  @override
  Future<Result<List<NonBarcodeItem>>> items() => _guard(() async {
    final rows = await _db.rawQuery(
      'SELECT n.item_id, n.description, n.price, n.depid, n.ageRefusal, d.name AS departmentName '
      'FROM nonBarcodeItems n LEFT JOIN departments d ON d.id = n.depid '
      'WHERE n.item_id NOT IN (888888, 999999) ORDER BY n.item_id',
    );
    return [
      for (final r in rows)
        NonBarcodeItem(
          itemId: r['item_id'] as int,
          description: r['description'] as String,
          priceCents: Money.toCents(r['price'] as num),
          departmentId: r['depid'] as int,
          departmentName: (r['departmentName'] as String?) ?? '',
          ageLimit: (r['ageRefusal'] as num?)?.toInt() ?? 0,
        ),
    ];
  });

  @override
  Future<Result<List<DepartmentOption>>> departments() =>
      _guard(() async => [for (final r in await _products.departments()) DepartmentOption.fromRow(r)]);

  @override
  Future<Result<int>> nextItemId() => _guard(() async {
    final rows = await _db.rawQuery('SELECT MAX(item_id) AS id FROM nonBarcodeItems WHERE item_id < ?', [_reserved.first]);
    final max = rows.first['id'] as int?;
    return max == null || max < _firstId ? _firstId : max + 1;
  });

  @override
  Future<Result<bool>> idExists(int itemId) => _guard(() async {
    if (_reserved.contains(itemId)) return true;
    final rows = await _db.query('nonBarcodeItems', columns: ['id'], where: 'item_id = ?', whereArgs: [itemId], limit: 1);
    return rows.isNotEmpty;
  });

  @override
  Future<Result<void>> add(NonBarcodeItem item, {required double vat}) => _guard(
    () => _db.insert('nonBarcodeItems', {
      'item_id': item.itemId,
      'description': item.description,
      'vat': vat,
      'depid': item.departmentId,
      'price': Money.fromCents(item.priceCents),
      'image_path': '',
      'ageRefusal': item.ageLimit,
    }),
  );

  @override
  Future<Result<void>> delete(int itemId) =>
      _guard(() => _db.delete('nonBarcodeItems', where: 'item_id = ?', whereArgs: [itemId]));

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }
}
