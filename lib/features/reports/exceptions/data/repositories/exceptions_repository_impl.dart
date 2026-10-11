import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/db_date.dart';
import '../../../../../core/utils/money.dart';
import '../../domain/entities/exception_record.dart';
import '../../domain/repositories/exceptions_repository.dart';

class ExceptionsRepositoryImpl implements ExceptionsRepository {
  ExceptionsRepositoryImpl(this._db);

  final Database _db;

  static const _userJoin =
      'LEFT JOIN logDetails l ON l.LogId = {log} LEFT JOIN userDetails u ON CAST(u.id AS TEXT) = l.Userid';

  @override
  Future<Result<List<ExceptionRecord>>> records(ExceptionType type, {required DateTime from, required DateTime to, int? logId}) async {
    try {
      return Ok(type == ExceptionType.refund ? await _refunds(from, to, logId) : await _posRecords(type.recordType!, from, to, logId));
    } catch (e) {
      return Err(DatabaseFailure('Could not load exceptions: $e'));
    }
  }

  Future<List<ExceptionRecord>> _posRecords(String type, DateTime from, DateTime to, int? logId) async {
    final rows = await _db.rawQuery(
      'SELECT r.Rec_Id, r.Rec_Date, r.reason, r.Record, r.Rec_Item, u.userName FROM posRecords r '
      '${_userJoin.replaceAll('{log}', 'r.LogId')} '
      'WHERE r.Rec_Type = ? AND r.Rec_Date >= ? AND r.Rec_Date < ? ${logId == null ? '' : 'AND r.LogId = ?'} '
      'ORDER BY r.Rec_Id DESC LIMIT 500',
      [type, DbDate.format(from), DbDate.format(to), ?logId],
    );
    return [
      for (final r in rows)
        () {
          final items = _decodeItems(r['Rec_Item'] as String?);
          return ExceptionRecord(
            id: r['Rec_Id'] as int,
            at: DbDate.tryParse(r['Rec_Date'] as String?) ?? DateTime.now(),
            userName: (r['userName'] as String?) ?? '',
            reason: (r['reason'] as String?) ?? (r['Record'] as String? ?? ''),
            amountCents: items.fold(0, (s, i) => s + i.amountCents),
            items: items,
          );
        }(),
    ];
  }

  Future<List<ExceptionRecord>> _refunds(DateTime from, DateTime to, int? logId) async {
    final rows = await _db.rawQuery(
      'SELECT t.id, t.transaction_date, t.total_payable, t.type, u.userName FROM Transactions t '
      '${_userJoin.replaceAll('{log}', 'CAST(t.user_id AS INTEGER)')} '
      'WHERE t.total_payable < 0 AND t.transaction_date >= ? AND t.transaction_date < ? ${logId == null ? '' : 'AND t.user_id = ?'} '
      'ORDER BY t.id DESC LIMIT 500',
      [DbDate.format(from), DbDate.format(to), if (logId != null) '$logId'],
    );
    if (rows.isEmpty) return const [];
    final ids = [for (final r in rows) r['id'] as int];
    final lines = await _db.rawQuery(
      'SELECT transaction_id, item, quantity, price, amount FROM TransactionItems '
      'WHERE transaction_id IN (${List.filled(ids.length, '?').join(',')}) ORDER BY id',
      ids,
    );
    final byTx = <int, List<ExceptionItem>>{};
    for (final l in lines) {
      byTx.putIfAbsent(l['transaction_id'] as int, () => []).add(ExceptionItem(
        name: (l['item'] as String?) ?? '',
        quantity: l['quantity'] as int,
        priceCents: Money.toCents(l['price'] as num),
        amountCents: Money.toCents(l['amount'] as num),
      ));
    }
    return [
      for (final r in rows)
        ExceptionRecord(
          id: r['id'] as int,
          at: DbDate.tryParse(r['transaction_date'] as String?) ?? DateTime.now(),
          userName: (r['userName'] as String?) ?? '',
          reason: 'Refund · ${r['type'] ?? ''}',
          amountCents: Money.toCents(r['total_payable'] as num),
          items: byTx[r['id']] ?? const [],
        ),
    ];
  }

  /// Item lists are stored as JSON with `item_name`, `quantity`, `price`, `amount`.
  static List<ExceptionItem> _decodeItems(String? json) {
    if (json == null || json.isEmpty) return const [];
    final decoded = jsonDecode(json);
    if (decoded is! List) return const [];
    return [
      for (final m in decoded.whereType<Map>())
        ExceptionItem(
          name: '${m['item_name'] ?? ''}',
          quantity: (m['quantity'] as num?)?.toInt() ?? 0,
          priceCents: Money.toCents((m['price'] as num?) ?? 0),
          amountCents: Money.toCents((m['amount'] as num?) ?? ((m['price'] as num? ?? 0) * (m['quantity'] as num? ?? 0))),
        ),
    ];
  }
}
