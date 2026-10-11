import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/utils/money.dart';

/// Reads how a transaction was paid from its two payment slots.
///
/// `Transactions` keeps up to two payments: `method1`/`method1Id` and
/// `method2`/`method2Id`. Ids are 0 for cash, -1 for card, otherwise a
/// `paymentType.id`. Change (`cus_balance`) is always given in cash.
/// Rows saved without slot ids are read as one payment of their `type`.
class PaymentSlots {
  PaymentSlots(this._db);

  final Database _db;

  static const cashId = 0;
  static const cardId = -1;

  /// Columns a caller must select for [parts].
  static const columns = 'type, total_payable, method1, method2, method1Id, method2Id, cus_balance';

  Future<Map<int, String>> typeNames() async => {
    for (final r in await _db.query('paymentType', columns: ['id', 'payment_name'])) r['id'] as int: r['payment_name'] as String,
  };

  static int? idFor(String method, int? typeId) => switch (method) {
    'Cash' => cashId,
    'Card' => cardId,
    _ => typeId,
  };

  static String nameFor(Object? methodId, Map<int, String> typeNames) => switch (methodId) {
    cashId => 'Cash',
    cardId => 'Card',
    final int typeId => typeNames[typeId] ?? 'Other',
    _ => 'Other',
  };

  /// What each payment contributed, in slot order, as `(method, cents)`.
  /// The amounts are what was handed over; [changeCents] was given back.
  /// For a refund the amounts are negative (money paid out).
  static List<(String, int)> payments(Map<String, Object?> row, Map<int, String> typeNames) {
    final total = Money.toCents(row['total_payable'] as num);
    if (row['method1Id'] == null) return [((row['type'] as String?) ?? 'Other', total)];
    final sign = total < 0 ? -1 : 1;
    int slot(String key) => Money.toCents(double.tryParse('${row[key]}') ?? 0) * sign;
    return [
      (nameFor(row['method1Id'], typeNames), slot('method1')),
      if (row['method2Id'] != null) (nameFor(row['method2Id'], typeNames), slot('method2')),
    ];
  }

  /// Change given back in cash; 0 for rows read from their `type`.
  static int changeCents(Map<String, Object?> row) {
    if (row['method1Id'] == null) return 0;
    final total = Money.toCents(row['total_payable'] as num);
    return Money.toCents((row['cus_balance'] as num?) ?? 0) * (total < 0 ? -1 : 1);
  }

  /// Net takings per payment type: each payment, less change from cash.
  /// The values always add up to `total_payable`.
  static Map<String, int> net(Map<String, Object?> row, Map<int, String> typeNames) {
    final out = <String, int>{};
    void add(String method, int value) {
      if (value != 0) out[method] = (out[method] ?? 0) + value;
    }

    for (final (method, cents) in payments(row, typeNames)) {
      add(method, cents);
    }
    add('Cash', -changeCents(row));
    return out;
  }
}
