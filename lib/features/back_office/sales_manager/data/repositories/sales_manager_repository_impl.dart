import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/db_date.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../infrastructure/database/dao/payment_slots.dart';
import '../../domain/entities/sale_line.dart';
import '../../domain/repositories/sales_manager_repository.dart';

class SalesManagerRepositoryImpl implements SalesManagerRepository {
  SalesManagerRepositoryImpl(this._db) : _slots = PaymentSlots(_db);

  final Database _db;
  final PaymentSlots _slots;

  /// `logDetails.Status` of an open shift.
  static const _open = '1';

  @override
  Future<Result<List<ShiftOption>>> shifts(DateTime from, DateTime to) => _guard(() async {
    final rows = await _db.rawQuery('''
SELECT l.LogId, l.ShiftStarted, l.ShiftEnd, COALESCE(u.userName, l.Userid) AS userName
  FROM logDetails l LEFT JOIN userDetails u ON CAST(u.id AS TEXT) = l.Userid
 WHERE l.Status != ? AND l.ShiftStarted >= ? AND l.ShiftStarted < ?
 ORDER BY l.LogId DESC''', [_open, DbDate.format(from), DbDate.format(to)]);
    return [
      for (final r in rows)
        (
          logId: r['LogId'] as int,
          userName: '${r['userName']}',
          started: DbDate.tryParse(r['ShiftStarted'] as String?) ?? from,
          ended: DbDate.tryParse(r['ShiftEnd'] as String?),
        ),
    ];
  });

  @override
  Future<Result<List<SaleLine>>> lines(DateTime from, DateTime to, {int? logId}) => _guard(() async {
    final names = await _slots.typeNames();
    final rows = await _db.rawQuery('''
SELECT i.id AS itemId, i.transaction_id, i.item, i.quantity, i.price, i.amount,
       t.type, t.method1Id, t.method2Id
  FROM TransactionItems i
  JOIN Transactions t ON t.id = i.transaction_id
  JOIN logDetails l ON CAST(l.LogId AS TEXT) = t.user_id
 WHERE l.Status != ?1 AND t.transaction_date >= ?2 AND t.transaction_date < ?3
   AND (?4 IS NULL OR l.LogId = ?4)
   AND t.total_payable > 0 AND i.quantity > 0
 ORDER BY i.transaction_id, i.id''', [_open, DbDate.format(from), DbDate.format(to), logId]);
    return [
      for (final r in rows)
        (
          itemId: r['itemId'] as int,
          transactionId: r['transaction_id'] as int,
          description: '${r['item'] ?? ''}',
          quantity: r['quantity'] as int,
          priceCents: Money.toCents(r['price'] as num),
          amountCents: Money.toCents(r['amount'] as num),
          kind: _kind(r),
          payment: _payment(r, names),
        ),
    ];
  });

  static PayKind _kind(Map<String, Object?> r) {
    final first = r['method1Id'], second = r['method2Id'];
    if (r['type'] == 'PartPay' || (second != null && second != first)) return PayKind.partPay;
    return switch (first ?? r['type']) {
      PaymentSlots.cashId || 'Cash' => PayKind.cash,
      PaymentSlots.cardId || 'Card' => PayKind.card,
      _ => PayKind.other,
    };
  }

  static String _payment(Map<String, Object?> r, Map<int, String> names) {
    if (r['method1Id'] == null) return '${r['type'] ?? 'Other'}';
    final methods = {PaymentSlots.nameFor(r['method1Id'], names), if (r['method2Id'] != null) PaymentSlots.nameFor(r['method2Id'], names)};
    return methods.join(' + ');
  }

  @override
  Future<Result<void>> remove(List<SaleLine> lines) => _guard(() => _db.transaction((txn) async {
    for (final line in lines) {
      await _returnToStock(txn, line, line.quantity);
      await txn.delete('TransactionItems', where: 'id = ?', whereArgs: [line.itemId]);
    }
    for (final id in {for (final l in lines) l.transactionId}) {
      await _settle(txn, id);
    }
  }));

  @override
  Future<Result<void>> alter(SaleLine line, int quantity) => _guard(() => _db.transaction((txn) async {
    final amount = Money.fromCents(line.priceCents * quantity);
    await _returnToStock(txn, line, line.quantity - quantity, newQuantity: quantity, newAmount: amount);
    await txn.update('TransactionItems', {'quantity': quantity, 'amount': amount, 'cloudSync': 0}, where: 'id = ?', whereArgs: [line.itemId]);
    await _settle(txn, line.transactionId);
  }));

  /// Puts [returned] units back in stock and updates (or, with no
  /// [newQuantity], deletes) the matching `SoldItems` row.
  Future<void> _returnToStock(Transaction txn, SaleLine line, int returned, {int? newQuantity, double? newAmount}) async {
    final sold = await txn.query(
      'SoldItems',
      columns: ['id', 'Barcode'],
      where: 'TranId = ? AND Description = ? AND Qty = ?',
      whereArgs: [line.transactionId, line.description, line.quantity],
      limit: 1,
    );
    final row = sold.firstOrNull;
    if (row == null) return;
    await txn.rawUpdate(
      'UPDATE products SET stock = stock + ?, cloudSync = 0 WHERE barcode = ?',
      [returned, row['Barcode']],
    );
    if (newQuantity == null) {
      await txn.delete('SoldItems', where: 'id = ?', whereArgs: [row['id']]);
    } else {
      await txn.update('SoldItems', {'Qty': newQuantity, 'Total': newAmount, 'cloudSync': 0}, where: 'id = ?', whereArgs: [row['id']]);
    }
  }

  /// Recomputes a sale from its remaining lines. The amount taken off is
  /// added to the change given back, so takings still match the total.
  /// A sale with nothing sold left is removed; a discount bigger than what
  /// is left is dropped.
  Future<void> _settle(Transaction txn, int transactionId) async {
    final sale = (await txn.query('Transactions', columns: ['total_payable', 'cus_balance'], where: 'id = ?', whereArgs: [transactionId])).first;
    var items = await txn.query('TransactionItems', columns: ['quantity', 'amount'], where: 'transaction_id = ?', whereArgs: [transactionId]);
    if (!items.any((i) => (i['quantity'] as int) > 0)) {
      await txn.delete('TransactionItems', where: 'transaction_id = ?', whereArgs: [transactionId]);
      await txn.delete('SoldItems', where: 'TranId = ?', whereArgs: [transactionId]);
      await txn.delete('Transactions', where: 'id = ?', whereArgs: [transactionId]);
      return;
    }
    int sum() => items.fold<int>(0, (s, i) => s + Money.toCents(i['amount'] as num));
    if (sum() < 0) {
      await txn.delete('TransactionItems', where: 'transaction_id = ? AND quantity = 0', whereArgs: [transactionId]);
      await txn.delete('SoldItems', where: 'TranId = ? AND Qty = 0', whereArgs: [transactionId]);
      items = items.where((i) => (i['quantity'] as int) > 0).toList();
    }
    final total = sum();
    final removed = Money.toCents(sale['total_payable'] as num) - total;
    await txn.update(
      'Transactions',
      {
        'total_payable': Money.fromCents(total),
        'cus_balance': Money.fromCents(Money.toCents(sale['cus_balance'] as num) + removed),
        'item_count': items.fold<int>(0, (n, i) => n + (i['quantity'] as int)),
        'cloudSync': 0,
      },
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }
}
