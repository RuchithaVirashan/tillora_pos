import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/db_date.dart';
import '../../../../../core/utils/money.dart';
import '../../domain/entities/back_office_report.dart';
import '../../domain/repositories/back_office_report_repository.dart';

class BackOfficeReportRepositoryImpl implements BackOfficeReportRepository {
  BackOfficeReportRepositoryImpl(this._db);

  final Database _db;

  /// Refund lines keep a positive quantity with a negative total, so
  /// they are subtracted.
  static const _netQty = 'SUM(CASE WHEN s.Total < 0 THEN -s.Qty ELSE s.Qty END)';

  /// `[?1 from, ?2 to)`, `?3` department, `?4` exact code, `?5` LIKE text.
  static List<Object?> _args(ReportFilter f) {
    final q = f.query.trim();
    return [
      DbDate.format(DateTime(f.from.year, f.from.month, f.from.day)),
      DbDate.format(DateTime(f.to.year, f.to.month, f.to.day + 1)),
      f.departmentId,
      q,
      '%$q%',
    ];
  }

  @override
  Future<Result<List<SaleRow>>> sales(ReportFilter filter) => _guard(() async {
    final rows = await _db.rawQuery('''
SELECT s.Barcode AS barcode, MAX(s.Description) AS description,
       COALESCE(MAX(d.name), MAX(s.type), '') AS category,
       $_netQty AS qty, MAX(s.Price) AS price, SUM(s.Total) AS total, MAX(p.costPrice) AS cost
  FROM SoldItems s
  JOIN Transactions t ON t.id = s.TranId
  LEFT JOIN products p ON p.barcode = s.Barcode
  LEFT JOIN departments d ON d.id = p.departmentId
 WHERE t.transaction_date >= ?1 AND t.transaction_date < ?2 AND s.Qty > 0
   AND (?3 IS NULL OR p.departmentId = ?3)
   AND (?4 = '' OR s.Barcode = ?4 OR s.Description LIKE ?5)
 GROUP BY s.Barcode, s.Description
 ORDER BY qty DESC, description''', _args(filter));
    return [
      for (final r in rows)
        (
          barcode: '${r['barcode']}',
          description: '${r['description']}',
          category: '${r['category']}',
          quantity: (r['qty'] as num).toInt(),
          unitPriceCents: Money.toCents(r['price'] as num),
          totalCents: Money.toCents(r['total'] as num),
          costCents: Money.toCents((r['cost'] as num?) ?? 0) * (r['qty'] as num).toInt(),
        ),
    ];
  });

  @override
  Future<Result<List<MovementRow>>> movement(ReportFilter filter) => _guard(() async {
    final rows = await _db.rawQuery('''
SELECT p.id, p.barcode, p.description, COALESCE(d.name, '') AS category, p.stock, p.price, COALESCE(m.sold, 0) AS sold
  FROM products p
  LEFT JOIN departments d ON d.id = p.departmentId
  LEFT JOIN (
    SELECT s.Barcode, $_netQty AS sold
      FROM SoldItems s JOIN Transactions t ON t.id = s.TranId
     WHERE t.transaction_date >= ?1 AND t.transaction_date < ?2 AND s.Qty > 0
     GROUP BY s.Barcode
  ) m ON m.Barcode = p.barcode
 WHERE (?3 IS NULL OR p.departmentId = ?3)
   AND (?4 = '' OR p.barcode = ?4 COLLATE NOCASE OR p.description LIKE ?5)
 ORDER BY p.description''', _args(filter));
    return [
      for (final r in rows)
        (
          productId: r['id'] as int,
          barcode: r['barcode'] as String,
          description: r['description'] as String,
          category: r['category'] as String,
          stock: r['stock'] as int,
          sold: (r['sold'] as num).toInt(),
          priceCents: Money.toCents(r['price'] as num),
        ),
    ];
  });

  @override
  Future<Result<List<AdjustmentRow>>> adjustments(ReportFilter filter) => _guard(() async {
    final rows = await _db.rawQuery('''
SELECT a.id, a.barcode, a.beforeStock, a.afterStock, a.adjustmentType, a.adjustedAt,
       COALESCE(p.description, '') AS description, COALESCE(d.name, '') AS category
  FROM stockAdjustment a
  LEFT JOIN products p ON p.barcode = a.barcode
  LEFT JOIN departments d ON d.id = p.departmentId
 WHERE a.adjustedAt >= ?1 AND a.adjustedAt < ?2
   AND (?3 IS NULL OR p.departmentId = ?3)
   AND (?4 = '' OR a.barcode = ?4 OR p.description LIKE ?5)
 ORDER BY a.adjustedAt DESC, a.id DESC''', _args(filter));
    return [
      for (final r in rows)
        (
          id: r['id'] as int,
          barcode: r['barcode'] as String,
          description: r['description'] as String,
          type: r['adjustmentType'] as String,
          before: r['beforeStock'] as int,
          after: r['afterStock'] as int,
          // Older rows log the size of the change without its sign.
          quantity: (r['afterStock'] as int) - (r['beforeStock'] as int),
          at: DbDate.tryParse(r['adjustedAt'] as String?) ?? DateTime(2000),
          category: r['category'] as String,
        ),
    ];
  });

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }
}
