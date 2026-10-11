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
          'promo': '',
          'promo_val': 0.0,
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
  /// One payment type: `type` is that type and `method1` its total.
  /// Mixed: `type` is `PartPay`, `method1` the cash total (id 0) and
  /// `method2` everything else (id -1 for card, the payment type id when
  /// it is a single other type). Every tender is counted, however many.
  static Map<String, Object?> _paymentColumns(List<Tender> tenders) {
    String amount(int cents) => Money.fromCents(cents).toStringAsFixed(2);
    final methods = {for (final t in tenders) t.method};
    if (methods.length <= 1) {
      return {
        'type': methods.firstOrNull ?? Tender.cashMethod,
        'method1': amount(tenders.fold(0, (s, t) => s + t.amountCents)),
        'method2': '0.0',
        'method1Id': tenders.firstOrNull?.typeId,
        'method2Id': null,
      };
    }
    final cash = tenders.where((t) => t.method == Tender.cashMethod);
    final other = tenders.where((t) => t.method != Tender.cashMethod).toList();
    final otherMethods = {for (final t in other) t.method};
    final otherId = otherMethods.length != 1
        ? null
        : otherMethods.single == Tender.cardMethod
        ? -1
        : other.first.typeId;
    return {
      'type': 'PartPay',
      'method1': amount(cash.fold(0, (s, t) => s + t.amountCents)),
      'method2': amount(other.fold(0, (s, t) => s + t.amountCents)),
      'method1Id': 0,
      'method2Id': otherId,
    };
  }
}
