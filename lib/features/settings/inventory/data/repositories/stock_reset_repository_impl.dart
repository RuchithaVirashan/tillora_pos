import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/db_date.dart';
import '../../domain/repositories/stock_reset_repository.dart';

class StockResetRepositoryImpl implements StockResetRepository {
  StockResetRepositoryImpl(this._db);

  final Database _db;

  @override
  Future<Result<StockSummary>> summary() => _guard(() async {
    final r = (await _db.rawQuery('SELECT COUNT(*) AS n, COALESCE(SUM(stock), 0) AS units FROM products WHERE stock != 0')).first;
    return (products: r['n'] as int, units: (r['units'] as num).toInt());
  });

  @override
  Future<Result<int>> reset() => _guard(() => _db.transaction((txn) async {
    final rows = await txn.query('products', columns: ['barcode', 'stock'], where: 'stock != 0');
    final at = DbDate.now();
    final batch = txn.batch();
    for (final r in rows) {
      final before = r['stock'] as int;
      batch.insert('stockAdjustment', {
        'barcode': r['barcode'],
        'beforeStock': before,
        'afterStock': 0,
        'adjustmentQuantity': -before,
        'adjustmentType': 'Stock Reset',
        'adjustedAt': at,
      });
    }
    batch.rawUpdate('UPDATE products SET stock = 0, cloudSync = 0 WHERE stock != 0');
    await batch.commit(noResult: true);
    return rows.length;
  }));

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }
}
