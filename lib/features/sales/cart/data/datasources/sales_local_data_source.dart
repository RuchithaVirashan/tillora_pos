import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/utils/db_date.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../infrastructure/database/dao/products_dao.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/sellable_item.dart';

class SalesLocalDataSource {
  SalesLocalDataSource(this._db, this._products);

  final Database _db;
  final ProductsDao _products;

  Future<Map<String, Object?>?> findByBarcode(String barcode) => _products.findByBarcode(barcode);

  Future<List<Map<String, Object?>>> quickItems() => _products.quickItems();

  Future<List<Map<String, Object?>>> weighedProducts(String query) => _products.weighedProducts(query);

  /// Promotions whose dates include [day] (`yyyy-MM-dd`), one row per
  /// promotion item.
  Future<List<Map<String, Object?>>> activePromotionItems(String day) => _db.rawQuery('''
SELECT p.id, p.description, p.promotionType, p.qty, p.amount, i.productId, i.groupId
  FROM promotions p JOIN promotionItems i ON i.promotionId = p.id
 WHERE p.startDate <= ?1 AND p.endDate >= ?1
 ORDER BY p.id, i.id''', [day]);

  Future<Map<int, String>> departmentNames() async {
    final rows = await _db.query('departments', columns: ['id', 'name']);
    return {for (final r in rows) r['id'] as int: r['name'] as String};
  }

  /// Everything is written in one database transaction, so a crash mid-sale
  /// cannot leave a transaction without its lines.
  Future<int> saveSale(Cart cart, {required int logId, required Map<int, String> departments}) {
    return _db.transaction((txn) async {
      final sign = cart.refund ? -1 : 1;
      final pay = _paymentColumns(cart.tenders);

      final transactionId = await txn.insert('Transactions', {
        'total_payable': Money.fromCents(cart.totalCents),
        'cus_paid_amount': Money.fromCents(cart.paidCents),
        'cus_balance': Money.fromCents(cart.changeCents),
        'transaction_date': DbDate.now(),
        ...pay,
        // Holds the shift id; reports group transactions by it.
        'user_id': '$logId',
        'item_count': cart.itemCount,
      });

      final batch = txn.batch();
      for (final line in cart.lines) {
        final item = line.item;
        final amount = Money.fromCents(line.amountCents * sign);
        // Discounts are stored with no quantity or unit price, only the amount.
        final isDiscount = item.source == ItemSource.discount;
        final quantity = isDiscount ? 0 : line.quantity;
        final price = isDiscount ? 0.0 : Money.fromCents(item.priceCents);
        batch.insert('TransactionItems', {
          'transaction_id': transactionId,
          'item': item.description,
          'quantity': quantity,
          'price': price,
          'amount': amount,
          'dep_id': item.departmentId,
          'vat': item.vat,
          // Promotion lines name their promotion and the discount given.
          'promo': line.isPromotion ? jsonEncode({'promoId': line.promotionId}) : '',
          'promo_val': line.isPromotion ? Money.fromCents(-line.amountCents) : 0.0,
          'productId': item.source == ItemSource.product ? item.productId : null,
        });
        batch.insert('SoldItems', {
          'TranId': transactionId,
          'Price': price,
          'Qty': quantity,
          'Total': amount,
          'logid': logId,
          'Description': item.description,
          'Barcode': item.barcode,
          'type': item.departmentName.isNotEmpty ? item.departmentName : (departments[item.departmentId] ?? ''),
        });
        if (item.source == ItemSource.product && item.productId != null) {
          batch.rawUpdate(
            'UPDATE products SET stock = stock - ?, cloudSync = 0 WHERE id = ?',
            [line.quantity * sign, item.productId],
          );
        }
      }
      await batch.commit(noResult: true);
      return transactionId;
    });
  }

  /// `type`, `method1/2` and `method1/2Id` for the tenders.
  ///
  /// A sale has at most two payments, one per slot. Ids: 0 cash, -1 card,
  /// otherwise the payment type id. Two different types make `PartPay`.
  static Map<String, Object?> _paymentColumns(List<Tender> tenders) {
    assert(tenders.length <= 2, 'A sale takes at most two payments');
    String amount(Tender? t) => t == null ? '0.0' : Money.fromCents(t.amountCents).toStringAsFixed(2);
    int? id(Tender? t) => switch (t?.method) {
      null => null,
      Tender.cashMethod => 0,
      Tender.cardMethod => -1,
      _ => t!.typeId,
    };
    final first = tenders.elementAtOrNull(0);
    final second = tenders.elementAtOrNull(1);
    final methods = {for (final t in tenders) t.method};
    return {
      'type': methods.length > 1 ? 'PartPay' : (methods.firstOrNull ?? Tender.cashMethod),
      'method1': amount(first),
      'method2': amount(second),
      'method1Id': id(first),
      'method2Id': id(second),
    };
  }
}
