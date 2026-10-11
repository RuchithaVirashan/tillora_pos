import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/db_date.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../infrastructure/database/dao/pos_records_dao.dart';
import '../../../../../infrastructure/database/dao/shift_dao.dart';
import '../../domain/entities/shift_summary.dart';
import '../../domain/repositories/shift_repository.dart';

class ShiftRepositoryImpl implements ShiftRepository {
  ShiftRepositoryImpl(this._db, this._shifts, this._records);

  final Database _db;
  final ShiftDao _shifts;
  final PosRecordsDao _records;

  @override
  Future<Result<void>> closeShift(int logId, {required int drawerFloatCents}) async {
    try {
      await _shifts.closeShift(logId, drawerFloat: Money.fromCents(drawerFloatCents));
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseFailure('Could not close the shift: $e'));
    }
  }

  /// Each section is one grouped query.
  @override
  Future<Result<ShiftSummary>> summary(int logId, {required String userName}) async {
    try {
      final id = '$logId';
      final shift = await _shifts.byId(logId);
      final byMethod = await _db.rawQuery(
        'SELECT type, SUM(total_payable) AS total, COUNT(*) AS n FROM Transactions '
        'WHERE user_id = ? AND total_payable > 0 GROUP BY type',
        [id],
      );
      final refunds = await _db.rawQuery(
        'SELECT COALESCE(SUM(total_payable), 0) AS total FROM Transactions WHERE user_id = ? AND total_payable < 0',
        [id],
      );
      final byDept = await _db.rawQuery(
        'SELECT type, SUM(Total) AS total FROM SoldItems WHERE logid = ? GROUP BY type ORDER BY total DESC',
        [logId],
      );
      final byHour = await _db.rawQuery(
        "SELECT CAST(strftime('%H', transaction_date) AS INTEGER) AS hour, SUM(total_payable) AS total "
        'FROM Transactions WHERE user_id = ? GROUP BY hour ORDER BY hour',
        [id],
      );
      final lifts = await _db.rawQuery('SELECT COALESCE(SUM(amount), 0) AS total FROM cashLift WHERE logId = ?', [logId]);

      int cents(Object? v) => Money.toCents((v as num?) ?? 0);
      final salesByMethod = {for (final r in byMethod) (r['type'] as String?) ?? 'Other': cents(r['total'])};
      // Net refunds into their payment type so cash in the drawer is right.
      final refundRows = await _db.rawQuery(
        'SELECT type, SUM(total_payable) AS total FROM Transactions WHERE user_id = ? AND total_payable < 0 GROUP BY type',
        [id],
      );
      for (final r in refundRows) {
        final type = (r['type'] as String?) ?? 'Other';
        salesByMethod[type] = (salesByMethod[type] ?? 0) + cents(r['total']);
      }

      return Ok(ShiftSummary(
        userName: userName,
        startedAt: DbDate.tryParse(shift?['ShiftStarted'] as String?) ?? DateTime.now(),
        endedAt: DbDate.tryParse(shift?['ShiftEnd'] as String?) ?? DateTime.now(),
        drawerFloatCents: cents(shift?['drawfloat']),
        salesByMethod: salesByMethod,
        refundsCents: cents(refunds.first['total']),
        cashLiftsCents: cents(lifts.first['total']),
        salesByDepartment: {
          for (final r in byDept) ((r['type'] as String?)?.isNotEmpty ?? false) ? r['type'] as String : 'Other': cents(r['total']),
        },
        salesByHour: {for (final r in byHour) (r['hour'] as int?) ?? 0: cents(r['total'])},
        transactionCount: byMethod.fold(0, (n, r) => n + (r['n'] as int)),
        noSaleCount: await _records.countForShift(PosRecordsDao.noSale, logId),
        voidLineCount: await _records.countForShift(PosRecordsDao.voidLine, logId),
        voidSaleCount: await _records.countForShift(PosRecordsDao.voidSale, logId),
      ));
    } catch (e) {
      return Err(DatabaseFailure('Could not build the shift report: $e'));
    }
  }
}
