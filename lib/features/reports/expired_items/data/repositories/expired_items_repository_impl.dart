import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/db_date.dart';
import '../../domain/repositories/expired_items_repository.dart';

class ExpiredItemsRepositoryImpl implements ExpiredItemsRepository {
  ExpiredItemsRepositoryImpl(this._db);

  final Database _db;

  @override
  Future<Result<List<ExpiredProduct>>> expired(DateTime onOrBefore) async {
    try {
      // Expiry dates are stored as yyyy-MM-dd (sometimes with a time), so
      // compare on the date part only.
      final day = DateFormat('yyyy-MM-dd').format(onOrBefore);
      final rows = await _db.rawQuery(
        'SELECT p.barcode, p.description, p.expiryDate, p.stock, d.name AS departmentName FROM products p '
        'LEFT JOIN departments d ON d.id = p.departmentId '
        "WHERE p.expiryDate IS NOT NULL AND p.expiryDate != '' AND substr(p.expiryDate, 1, 10) <= ? "
        'ORDER BY p.expiryDate DESC LIMIT 1000',
        [day],
      );
      return Ok([
        for (final r in rows)
          (
            barcode: r['barcode'] as String,
            description: r['description'] as String,
            departmentName: (r['departmentName'] as String?) ?? '',
            expiryDate: DbDate.tryParse(r['expiryDate'] as String?) ?? onOrBefore,
            stock: (r['stock'] as num?)?.toInt() ?? 0,
          ),
      ]);
    } catch (e) {
      return Err(DatabaseFailure('Could not load expired items: $e'));
    }
  }
}
