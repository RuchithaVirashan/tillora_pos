import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/db_date.dart';
import '../../../../../core/utils/money.dart';
import '../../domain/entities/stock_entry.dart';
import '../../domain/repositories/stock_manager_repository.dart';

class StockManagerRepositoryImpl implements StockManagerRepository {
  StockManagerRepositoryImpl(this._db);

  final Database _db;

  static const _where = '''
 WHERE (p.caseBarcode IS NULL OR p.caseBarcode != 'weight')
   AND (?1 = '' OR p.barcode = ?1 COLLATE NOCASE OR p.description LIKE ?2)
   AND (?3 IS NULL OR p.departmentId = ?3)''';

  @override
  Future<Result<StockList>> stock({required String query, int? departmentId, int limit = 1000}) => _guard(() async {
    final args = [query, '%$query%', departmentId];
    final rows = await _db.rawQuery('''
SELECT p.id, p.barcode, p.description, p.stock, p.price, d.name AS department, s.name AS subDepartment
  FROM products p
  LEFT JOIN departments d ON d.id = p.departmentId
  LEFT JOIN subDepartments s ON s.id = p.subDeptId
$_where
 ORDER BY p.description
 LIMIT ?4''', [...args, limit]);
    // Stock below zero is not counted as value.
    final totals = (await _db.rawQuery('''
SELECT COUNT(*) AS n, COALESCE(SUM(CASE WHEN p.stock > 0 THEN p.price * p.stock END), 0) AS gross
  FROM products p
$_where''', args)).first;
    return (
      entries: [
        for (final r in rows)
          (
            productId: r['id'] as int,
            barcode: r['barcode'] as String,
            description: r['description'] as String,
            stock: r['stock'] as int,
            department: r['department'] as String? ?? '',
            subDepartment: r['subDepartment'] as String? ?? '',
            priceCents: Money.toCents(r['price'] as num),
          ),
      ],
      matched: totals['n'] as int,
      grossTotalCents: Money.toCents(totals['gross'] as num),
    );
  });

  @override
  Future<Result<int>> adjust(StockEntry entry, {required StockAdjustReason reason, required int delta}) => _guard(
    () => _db.transaction((txn) async {
      // Read inside the transaction so a sale in between is not lost.
      final before = (await txn.query('products', columns: ['stock'], where: 'id = ?', whereArgs: [entry.productId])).first['stock'] as int;
      final after = before + delta;
      await txn.update('products', {'stock': after, 'cloudSync': 0}, where: 'id = ?', whereArgs: [entry.productId]);
      await txn.insert('stockAdjustment', {
        'barcode': entry.barcode,
        'beforeStock': before,
        'afterStock': after,
        'adjustmentQuantity': delta,
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
