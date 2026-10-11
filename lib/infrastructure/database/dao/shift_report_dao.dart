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
    final payments = await _db.rawQuery(
      'SELECT type, total_payable, method1, method2, method1Id, method2Id, cus_balance FROM Transactions WHERE user_id = ?',
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

    // Takings per payment type. A sale's two payment slots (method1/2;
    // ids 0 cash, -1 card, else a payment type) are counted separately and
    // any change comes off cash, so card or voucher overpayments and split
    // payments land in the right place. Refunds and rows without slot ids
    // count their total under their type.
    final typeNames = {
      for (final r in await _db.query('paymentType', columns: ['id', 'payment_name'])) r['id'] as int: r['payment_name'] as String,
    };
    String name(Object? methodId) => switch (methodId) {
      0 => 'Cash',
      -1 => 'Card',
      final int typeId => typeNames[typeId] ?? 'Other',
      _ => 'Other',
    };
    final salesByMethod = <String, int>{};
    void add(String method, int value) {
      if (value != 0) salesByMethod[method] = (salesByMethod[method] ?? 0) + value;
    }

    for (final r in payments) {
      final total = cents(r['total_payable']);
      if (total < 0 || r['method1Id'] == null) {
        add((r['type'] as String?) ?? 'Other', total);
        continue;
      }
      add(name(r['method1Id']), cents(double.tryParse('${r['method1']}')));
      if (r['method2Id'] != null) add(name(r['method2Id']), cents(double.tryParse('${r['method2']}')));
      add('Cash', -cents(r['cus_balance']));
    }
    return ShiftSummary(
      userName: (shift?['userName'] as String?) ?? '',
      startedAt: DbDate.tryParse(shift?['ShiftStarted'] as String?) ?? DateTime.now(),
      endedAt: DbDate.tryParse(ended) ?? DateTime.now(),
      drawerFloatCents: cents(shift?['drawfloat']),
      salesByMethod: salesByMethod,
      refundsCents: cents(refunds.first['total']),
      cashLiftsCents: cents(lifts.first['total']),
      salesByDepartment: {
        for (final r in byDept) ((r['type'] as String?)?.isNotEmpty ?? false) ? r['type'] as String : 'Other': cents(r['total']),
      },
      salesByHour: {for (final r in byHour) (r['hour'] as int?) ?? 0: cents(r['total'])},
      transactionCount: payments.length,
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
