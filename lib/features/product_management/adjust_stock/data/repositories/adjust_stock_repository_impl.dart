import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/db_date.dart';
import '../../domain/repositories/adjust_stock_repository.dart';
import '../../domain/usecases/adjust_stock_usecases.dart';

class AdjustStockRepositoryImpl implements AdjustStockRepository {
  AdjustStockRepositoryImpl(this._db);

  final Database _db;

  @override
  Future<Result<StockItem?>> find(String query) => _guard(() async {
    final rows = await _db.rawQuery(
      'SELECT id, barcode, description, stock FROM products '
      "WHERE (caseBarcode IS NULL OR caseBarcode != 'weight') AND (barcode = ?1 COLLATE NOCASE OR description LIKE ?2) "
      'ORDER BY (barcode = ?1 COLLATE NOCASE) DESC, description LIMIT 1',
      [query, '%$query%'],
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return (productId: r['id'] as int, barcode: r['barcode'] as String, description: r['description'] as String, stock: r['stock'] as int);
  });

  @override
  Future<Result<int>> adjust(StockItem item, {required StockReason reason, required int quantity}) => _guard(
    () => _db.transaction((txn) async {
      // Read inside the transaction so a sale in between is not lost.
      final current = (await txn.query('products', columns: ['stock'], where: 'id = ?', whereArgs: [item.productId])).first['stock'] as int;
      final after = AdjustStock.newStock((productId: item.productId, barcode: item.barcode, description: item.description, stock: current), reason, quantity);
      await txn.update('products', {'stock': after, 'cloudSync': 0}, where: 'id = ?', whereArgs: [item.productId]);
      await txn.insert('stockAdjustment', {
        'barcode': item.barcode,
        'beforeStock': current,
        'afterStock': after,
        'adjustmentQuantity': quantity,
        'adjustmentType': reason.label,
        'adjustedAt': DbDate.now(),
      });
      return after;
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
