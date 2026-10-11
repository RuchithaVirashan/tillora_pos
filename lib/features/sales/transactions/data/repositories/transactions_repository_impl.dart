import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/db_date.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../infrastructure/database/dao/payment_slots.dart';
import '../../domain/entities/shift_transaction.dart';
import '../../domain/repositories/transactions_repository.dart';

class TransactionsRepositoryImpl implements TransactionsRepository {
  TransactionsRepositoryImpl(this._db);

  final Database _db;

  @override
  Future<Result<List<ShiftTransaction>>> forShift(int logId) => _guard(() async {
    final rows = await _db.rawQuery(
      'SELECT id, transaction_date, item_count, ${PaymentSlots.columns} FROM Transactions WHERE user_id = ? ORDER BY id DESC',
      ['$logId'],
    );
    final typeNames = await PaymentSlots(_db).typeNames();
    return [
      for (final r in rows)
        ShiftTransaction(
          id: r['id'] as int,
          at: DbDate.tryParse(r['transaction_date'] as String?) ?? DateTime.now(),
          method: (r['type'] as String?) ?? '',
          totalCents: Money.toCents(r['total_payable'] as num),
          itemCount: r['item_count'] as int,
          payments: [for (final (method, cents) in PaymentSlots.payments(r, typeNames)) (method: method, amountCents: cents)],
          changeCents: PaymentSlots.changeCents(r),
        ),
    ];
  });

  @override
  Future<Result<List<TransactionLine>>> lines(int transactionId) => _guard(() async {
    final rows = await _db.query(
      'TransactionItems',
      columns: ['item', 'quantity', 'amount'],
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
      orderBy: 'id',
    );
    return [
      for (final r in rows)
        TransactionLine(
          description: (r['item'] as String?) ?? '',
          quantity: r['quantity'] as int,
          amountCents: Money.toCents(r['amount'] as num),
        ),
    ];
  });

  @override
  Future<Result<List<PayTypeOption>>> payTypes() => _guard(() async {
    final rows = await _db.query('paymentType', columns: ['id', 'payment_name'], where: 'enabled = 1', orderBy: 'id');
    return [
      const PayTypeOption('Cash'),
      const PayTypeOption('Card'),
      for (final r in rows) PayTypeOption(r['payment_name'] as String, r['id'] as int),
    ];
  });

  @override
  /// Rewrites the payment as a single payment of the new type, so the
  /// slots, change and reports agree. Cash keeps the amount handed over and
  /// the change; any other type takes exactly the total, with no change.
  @override
  Future<Result<void>> changePayType(int transactionId, PayTypeOption to) => _guard(() {
    final methodId = PaymentSlots.idFor(to.name, to.id);
    final cash = methodId == PaymentSlots.cashId ? 1 : 0;
    // SQLite evaluates every SET expression against the old row values.
    return _db.rawUpdate(
      "UPDATE Transactions SET type = ?1, method1Id = ?2, method2 = '0.0', method2Id = NULL, "
      "method1 = printf('%.2f', CASE WHEN ?3 THEN cus_paid_amount ELSE ABS(total_payable) END), "
      'cus_paid_amount = CASE WHEN ?3 THEN cus_paid_amount ELSE ABS(total_payable) END, '
      'cus_balance = CASE WHEN ?3 THEN cus_balance ELSE 0 END, '
      'cloudSync = 0 WHERE id = ?4',
      [to.name, methodId, cash, transactionId],
    );
  });

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }
}
