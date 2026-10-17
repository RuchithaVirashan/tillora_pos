import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/db_date.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../infrastructure/database/dao/payment_slots.dart';
import '../../../../sales/cart/domain/entities/active_promotion.dart';
import '../../../../sales/cart/domain/entities/cart.dart';
import '../../../../sales/cart/domain/entities/sellable_item.dart';
import '../../../../sales/cart/domain/usecases/apply_promotions.dart';
import '../../../promotions/domain/entities/promotion.dart';
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
    final sales = {for (final l in lines) l.transactionId};
    final tracked = {for (final id in sales) if (await _tracksProducts(txn, id)) id};
    for (final line in lines) {
      await _returnToStock(txn, line, line.quantity);
      await txn.delete('TransactionItems', where: 'id = ?', whereArgs: [line.itemId]);
    }
    for (final id in {for (final l in lines) l.transactionId}) {
      if (tracked.contains(id)) await _repricePromotions(txn, id);
      await _settle(txn, id);
    }
  }));

  @override
  Future<Result<void>> alter(SaleLine line, int quantity) => _guard(() => _db.transaction((txn) async {
    final amount = Money.fromCents(line.priceCents * quantity);
    await _returnToStock(txn, line, line.quantity - quantity, newQuantity: quantity, newAmount: amount);
    await txn.update('TransactionItems', {'quantity': quantity, 'amount': amount, 'cloudSync': 0}, where: 'id = ?', whereArgs: [line.itemId]);
    if (await _tracksProducts(txn, line.transactionId)) await _repricePromotions(txn, line.transactionId);
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
  /// The sale recorded which product each line was. Older sales did not,
  /// so their promotion discounts are left as they were.
  Future<bool> _tracksProducts(Transaction txn, int transactionId) async => (await txn.query(
    'TransactionItems',
    columns: ['id'],
    where: 'transaction_id = ? AND productId IS NOT NULL',
    whereArgs: [transactionId],
    limit: 1,
  )).isNotEmpty;

  /// Works the sale's promotion discounts out again from the products left
  /// on it, using the same rules as the till. A promotion that no longer
  /// applies loses its line; one since deleted keeps its discount.
  Future<void> _repricePromotions(Transaction txn, int transactionId) async {
    final items = await txn.query(
      'TransactionItems',
      columns: ['id', 'item', 'quantity', 'price', 'amount', 'promo', 'productId'],
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    final promoLines = <int, Map<String, Object?>>{
      for (final i in items) ?_promotionId(i['promo']): i,
    };
    if (promoLines.isEmpty) return;

    final rows = await txn.rawQuery('''
SELECT p.id, p.description, p.promotionType, p.qty, p.amount, i.productId, i.groupId
  FROM promotions p JOIN promotionItems i ON i.promotionId = p.id
 WHERE p.id IN (${List.filled(promoLines.length, '?').join(',')})''', promoLines.keys.toList());
    final groups = <int, Map<int, Set<int>>>{};
    final promos = <int, Map<String, Object?>>{};
    for (final r in rows) {
      final id = r['id'] as int;
      promos[id] = r;
      groups.putIfAbsent(id, () => {}).putIfAbsent((r['groupId'] as int?) ?? 1, () => {}).add(r['productId'] as int);
    }
    final active = [
      for (final MapEntry(key: id, value: r) in promos.entries)
        ActivePromotion(
          id: id,
          description: r['description'] as String,
          type: PromoType.fromLabel(r['promotionType'] as String),
          qty: int.tryParse('${r['qty']}') ?? 1,
          amountCents: Money.toCents((r['amount'] as num?) ?? 0),
          groups: groups[id]!,
        ),
    ];

    var cart = Cart.empty;
    for (final i in items) {
      final productId = i['productId'] as int?;
      final quantity = i['quantity'] as int;
      if (productId == null || quantity <= 0) continue;
      cart = cart.add(
        SellableItem(productId: productId, description: '${i['item']}', barcode: '$productId', priceCents: Money.toCents(i['price'] as num), departmentId: 0),
        quantity,
      );
    }
    final discounts = {for (final l in ApplyPromotions.discountLines(cart, active)) l.promotionId!: -l.amountCents};

    for (final MapEntry(key: id, value: line) in promoLines.entries) {
      if (!promos.containsKey(id)) continue;
      final cents = discounts[id] ?? 0;
      final oldAmount = line['amount'] as num;
      final sold = {'TranId': transactionId, 'Description': line['item'], 'Qty': 0, 'Total': oldAmount};
      final soldWhere = sold.keys.map((k) => '$k = ?').join(' AND ');
      if (cents <= 0) {
        await txn.delete('TransactionItems', where: 'id = ?', whereArgs: [line['id']]);
        await txn.delete('SoldItems', where: soldWhere, whereArgs: sold.values.toList());
      } else if (cents != -Money.toCents(oldAmount)) {
        final amount = Money.fromCents(-cents);
        await txn.update('TransactionItems', {'amount': amount, 'promo_val': Money.fromCents(cents), 'cloudSync': 0}, where: 'id = ?', whereArgs: [line['id']]);
        await txn.update('SoldItems', {'Total': amount, 'cloudSync': 0}, where: soldWhere, whereArgs: sold.values.toList());
      }
    }
  }

  static int? _promotionId(Object? promo) {
    if (promo is! String || promo.isEmpty) return null;
    try {
      return ((jsonDecode(promo) as Map)['promoId'] as num?)?.toInt();
    } on FormatException {
      return null;
    }
  }

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
