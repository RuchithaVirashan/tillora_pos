import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/reports/shift_summary.dart';
import '../../../core/utils/db_date.dart';
import '../../../core/utils/money.dart';
import 'pos_records_dao.dart';

/// Shift report figures, shared by Shift End and the shift reports.
class ShiftReportDao {
  ShiftReportDao(this._db, this._records);

  final Database _db;
  final PosRecordsDao _records;

  /// Each section is one grouped query.
  Future<ShiftSummary> summary(int logId) async {
    final id = '$logId';
    final shift = (await _db.rawQuery(
      'SELECT l.ShiftStarted, l.ShiftEnd, l.drawfloat, u.userName FROM logDetails l '
      'LEFT JOIN userDetails u ON CAST(u.id AS TEXT) = l.Userid WHERE l.LogId = ?',
      [logId],
    )).firstOrNull;
    final byMethod = await _db.rawQuery(
      'SELECT type, SUM(total_payable) AS total, COUNT(*) AS n FROM Transactions WHERE user_id = ? GROUP BY type',
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
    final ended = shift?['ShiftEnd'] as String?;
    return ShiftSummary(
      userName: (shift?['userName'] as String?) ?? '',
      startedAt: DbDate.tryParse(shift?['ShiftStarted'] as String?) ?? DateTime.now(),
      endedAt: DbDate.tryParse(ended) ?? DateTime.now(),
      drawerFloatCents: cents(shift?['drawfloat']),
      salesByMethod: {for (final r in byMethod) (r['type'] as String?) ?? 'Other': cents(r['total'])},
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
    );
  }

  /// Shifts for the report pickers, newest first. [openOnly] for live shifts.
  Future<List<Map<String, Object?>>> shifts({bool openOnly = false, DateTime? from, DateTime? to, int? userId}) {
    final where = <String>[];
    final args = <Object?>[];
    if (openOnly) where.add("l.Status = '1'");
    void filter(String clause, Object value) {
      where.add(clause);
      args.add(value);
    }

    if (from != null) filter('l.ShiftStarted >= ?', DbDate.format(from));
    if (to != null) filter('l.ShiftStarted < ?', DbDate.format(to));
    if (userId != null) filter('l.Userid = ?', '$userId');
    return _db.rawQuery(
      'SELECT l.LogId, l.ShiftStarted, l.ShiftEnd, l.Status, u.userName FROM logDetails l '
      'LEFT JOIN userDetails u ON CAST(u.id AS TEXT) = l.Userid '
      '${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'} ORDER BY l.LogId DESC LIMIT 200',
      args,
    );
  }

  Future<List<Map<String, Object?>>> users() => _db.query('userDetails', columns: ['id', 'userName'], orderBy: 'userName');
}
