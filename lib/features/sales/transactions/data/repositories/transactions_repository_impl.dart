import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/db_date.dart';
import '../../../../../core/utils/money.dart';
import '../../domain/entities/shift_transaction.dart';
import '../../domain/repositories/transactions_repository.dart';

class TransactionsRepositoryImpl implements TransactionsRepository {
  TransactionsRepositoryImpl(this._db);

  final Database _db;

  @override
  Future<Result<List<ShiftTransaction>>> forShift(int logId) => _guard(() async {
    final rows = await _db.query(
      'Transactions',
      columns: ['id', 'transaction_date', 'type', 'method1Id', 'total_payable', 'item_count'],
      where: 'user_id = ?',
      whereArgs: ['$logId'],
      orderBy: 'id DESC',
    );
    return [
      for (final r in rows)
        ShiftTransaction(
          id: r['id'] as int,
          at: DbDate.tryParse(r['transaction_date'] as String?) ?? DateTime.now(),
          method: (r['type'] as String?) ?? '',
          methodId: r['method1Id'] as int?,
          totalCents: Money.toCents(r['total_payable'] as num),
          itemCount: r['item_count'] as int,
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
  Future<Result<void>> changePayType(int transactionId, PayTypeOption to) => _guard(
    () => _db.update(
      'Transactions',
      {'type': to.name, 'method1Id': to.id, 'cloudSync': 0},
      where: 'id = ?',
      whereArgs: [transactionId],
    ),
  );

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }
}
