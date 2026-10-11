import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/receipts/receipt.dart';
import '../../../core/utils/db_date.dart';
import '../../../core/utils/money.dart';
import 'payment_slots.dart';
import 'sys_config_dao.dart';

/// Builds a [Receipt] for a saved transaction.
class ReceiptDao {
  ReceiptDao(this._db, this._config);

  final Database _db;
  final SysConfigDao _config;

  Future<Receipt?> forTransaction(int transactionId) async {
    final rows = await _db.rawQuery(
      'SELECT t.id, t.transaction_date, t.item_count, ${_qualified('t')}, u.userName '
      'FROM Transactions t '
      'LEFT JOIN logDetails l ON l.LogId = CAST(t.user_id AS INTEGER) '
      'LEFT JOIN userDetails u ON CAST(u.id AS TEXT) = l.Userid '
      'WHERE t.id = ?',
      [transactionId],
    );
    if (rows.isEmpty) return null;
    final t = rows.first;

    final items = await _db.query(
      'TransactionItems',
      columns: ['item', 'quantity', 'price', 'amount'],
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
      orderBy: 'id',
    );
    final config = await _config.getMany(['receiptHeader', 'receiptFooter', 'terminalName']);
    final company = await _config.companyName();
    final typeNames = await PaymentSlots(_db).typeNames();

    List<String> split(String? text) => [
      for (final line in (text ?? '').split('\n'))
        if (line.trim().isNotEmpty) line.trim(),
    ];
    final header = split(config['receiptHeader']);

    return Receipt(
      transactionId: transactionId,
      at: DbDate.tryParse(t['transaction_date'] as String?) ?? DateTime.now(),
      header: header.isEmpty ? [if (company.isNotEmpty) company] : header,
      footer: split(config['receiptFooter']),
      cashier: (t['userName'] as String?) ?? '',
      terminal: config['terminalName'] ?? '',
      lines: [
        for (final i in items)
          ReceiptLine(
            name: (i['item'] as String?) ?? '',
            quantity: i['quantity'] as int,
            priceCents: Money.toCents(i['price'] as num),
            amountCents: Money.toCents(i['amount'] as num),
          ),
      ],
      itemCount: t['item_count'] as int,
      totalCents: Money.toCents(t['total_payable'] as num),
      payments: PaymentSlots.payments(t, typeNames),
      changeCents: PaymentSlots.changeCents(t),
    );
  }

  /// [PaymentSlots.columns] with a table alias.
  static String _qualified(String alias) => PaymentSlots.columns.split(', ').map((c) => '$alias.$c').join(', ');
}
