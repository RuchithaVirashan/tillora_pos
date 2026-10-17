import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../infrastructure/database/tables/schema.dart';
import '../../domain/entities/maintenance_tool.dart';
import '../../domain/repositories/maintenance_repository.dart';

class MaintenanceRepositoryImpl implements MaintenanceRepository {
  MaintenanceRepositoryImpl(this._db);

  final Database _db;

  /// Sales (not refunds) whose total differs from the sum of their lines.
  static const _totalMismatch = '''
SELECT t.id, t.total_payable, t.cus_balance, s.total
  FROM Transactions t
  JOIN (SELECT transaction_id, SUM(amount) AS total FROM TransactionItems GROUP BY transaction_id) s ON s.transaction_id = t.id
 WHERE t.total_payable > 0 AND s.total > 0 AND ABS(t.total_payable - s.total) > 0.005''';

  /// Change should be what was paid less the total.
  static const _balanceMismatch = '''
FROM Transactions
 WHERE total_payable > 0 AND cus_paid_amount >= total_payable
   AND ABS(cus_balance - (cus_paid_amount - total_payable)) > 0.005''';

  /// Two different payment types not marked PartPay, or PartPay with one.
  static const _partPayWrong = '''
FROM Transactions
 WHERE (method2Id IS NOT NULL AND method2Id != method1Id AND COALESCE(type, '') != 'PartPay')
    OR (type = 'PartPay' AND method1Id IS NOT NULL AND (method2Id IS NULL OR method2Id = method1Id))''';

  static const _orphanItems = 'FROM TransactionItems WHERE transaction_id NOT IN (SELECT id FROM Transactions)';
  static const _orphanSold = 'FROM SoldItems WHERE TranId NOT IN (SELECT id FROM Transactions)';
  static const _emptySales = 'FROM Transactions t WHERE NOT EXISTS (SELECT 1 FROM TransactionItems i WHERE i.transaction_id = t.id)';
  static const _noDepartment = 'FROM products WHERE departmentId NOT IN (SELECT id FROM departments)';

  static Set<String> get _expectedTables => {
    for (final sql in Schema.tables)
      if (RegExp(r'CREATE TABLE IF NOT EXISTS (\w+)').firstMatch(sql) case final m?) m[1]!,
  };

  Future<int> _count(DatabaseExecutor db, String from) async => (await db.rawQuery('SELECT COUNT(*) AS n $from')).first['n'] as int;

  Future<Set<String>> _missingTables(DatabaseExecutor db) async {
    final rows = await db.rawQuery("SELECT name FROM sqlite_master WHERE type = 'table'");
    final existing = {for (final r in rows) r['name'] as String};
    return _expectedTables.difference(existing);
  }

  @override
  Future<Result<MaintenanceFinding>> inspect(MaintenanceTool tool) => _guard(() async {
    switch (tool) {
      case MaintenanceTool.databaseCheck:
        final rows = await _db.rawQuery('PRAGMA integrity_check');
        final problems = [for (final r in rows) '${r.values.first}'].where((v) => v != 'ok').toList();
        final missing = await _missingTables(_db);
        final sales = await _count(_db, 'FROM Transactions');
        final products = await _count(_db, 'FROM products');
        return (
          count: problems.length + missing.length,
          detail: problems.isEmpty && missing.isEmpty
              ? 'Database is healthy: $products products, $sales sales.'
              : [...problems.take(5), if (missing.isNotEmpty) 'Missing tables: ${missing.join(', ')}'].join('\n'),
        );
      case MaintenanceTool.tables:
        final missing = await _missingTables(_db);
        return (
          count: missing.length,
          detail: missing.isEmpty ? 'All ${_expectedTables.length} tables are present.' : 'Missing: ${missing.join(', ')}',
        );
      case MaintenanceTool.transactionTotals:
        final n = (await _db.rawQuery(_totalMismatch)).length;
        return (count: n, detail: n == 0 ? 'Every sale total matches its items.' : '$n sales have a total that does not match their items.');
      case MaintenanceTool.balances:
        final n = await _count(_db, _balanceMismatch);
        return (count: n, detail: n == 0 ? 'Change is correct on every sale.' : '$n sales have the wrong change recorded.');
      case MaintenanceTool.partPay:
        final n = await _count(_db, _partPayWrong);
        return (count: n, detail: n == 0 ? 'Every payment type is correct.' : '$n sales have the wrong payment type.');
      case MaintenanceTool.orphanItems:
        final items = await _count(_db, _orphanItems);
        final sold = await _count(_db, _orphanSold);
        return (count: items + sold, detail: items + sold == 0 ? 'Every item line belongs to a sale.' : '${items + sold} item lines belong to sales that no longer exist.');
      case MaintenanceTool.emptyTransactions:
        final n = await _count(_db, _emptySales);
        return (count: n, detail: n == 0 ? 'Every sale has items.' : '$n sales have no items.');
      case MaintenanceTool.noDepartment:
        final n = await _count(_db, _noDepartment);
        return (count: n, detail: n == 0 ? 'Every product has a department.' : '$n products have no valid department.');
    }
  });

  @override
  Future<Result<int>> fix(MaintenanceTool tool) => _guard(() => _db.transaction((txn) async {
    switch (tool) {
      case MaintenanceTool.databaseCheck:
        return 0;
      case MaintenanceTool.tables:
        final missing = await _missingTables(txn);
        for (final sql in [...Schema.tables, ...Schema.indexes]) {
          await txn.execute(sql);
        }
        return missing.length;
      case MaintenanceTool.transactionTotals:
        final rows = await txn.rawQuery(_totalMismatch);
        for (final r in rows) {
          final total = Money.toCents(r['total'] as num);
          // The difference is counted as change, so takings still match.
          final change = Money.toCents(r['cus_balance'] as num) + Money.toCents(r['total_payable'] as num) - total;
          await txn.update(
            'Transactions',
            {'total_payable': Money.fromCents(total), 'cus_balance': Money.fromCents(change), 'cloudSync': 0},
            where: 'id = ?',
            whereArgs: [r['id']],
          );
        }
        return rows.length;
      case MaintenanceTool.balances:
        return txn.rawUpdate('UPDATE Transactions SET cus_balance = ROUND(cus_paid_amount - total_payable, 2), cloudSync = 0 WHERE id IN (SELECT id $_balanceMismatch)');
      case MaintenanceTool.partPay:
        final split = await txn.rawUpdate(
          "UPDATE Transactions SET type = 'PartPay', cloudSync = 0 "
          "WHERE method2Id IS NOT NULL AND method2Id != method1Id AND COALESCE(type, '') != 'PartPay'",
        );
        final single = await txn.rawUpdate('''
UPDATE Transactions SET cloudSync = 0, type = CASE method1Id
    WHEN 0 THEN 'Cash' WHEN -1 THEN 'Card'
    ELSE COALESCE((SELECT payment_name FROM paymentType p WHERE p.id = Transactions.method1Id), 'Other') END
 WHERE type = 'PartPay' AND method1Id IS NOT NULL AND (method2Id IS NULL OR method2Id = method1Id)''');
        return split + single;
      case MaintenanceTool.orphanItems:
        return await txn.rawDelete('DELETE $_orphanItems') + await txn.rawDelete('DELETE $_orphanSold');
      case MaintenanceTool.emptyTransactions:
        await txn.rawDelete('DELETE FROM SoldItems WHERE TranId IN (SELECT t.id $_emptySales)');
        return txn.rawDelete('DELETE FROM Transactions WHERE id IN (SELECT t.id $_emptySales)');
      case MaintenanceTool.noDepartment:
        final target = (await txn.rawQuery('SELECT COALESCE((SELECT id FROM departments WHERE id = 10), (SELECT MIN(id) FROM departments)) AS id')).first['id'];
        if (target == null) throw StateError('Add a department first');
        return txn.rawUpdate('UPDATE products SET departmentId = ?, cloudSync = 0 WHERE departmentId NOT IN (SELECT id FROM departments)', [target]);
    }
  }));

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }
}
