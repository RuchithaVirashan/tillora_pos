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

  Future<Map<int, String>> departmentNames() async {
    final rows = await _db.query('departments', columns: ['id', 'name']);
    return {for (final r in rows) r['id'] as int: r['name'] as String};
  }

  /// Everything is written in one database transaction, so a crash mid-sale
  /// cannot leave a transaction without its lines.
  Future<int> saveSale(Cart cart, {required int logId, required Map<int, String> departments}) {
    return _db.transaction((txn) async {
      final sign = cart.refund ? -1 : 1;
      final tenders = cart.tenders;
      final methods = tenders.map((t) => t.method).toSet();
      final type = methods.length == 1 ? methods.first : 'PartPay';

      final transactionId = await txn.insert('Transactions', {
        'total_payable': Money.fromCents(cart.totalCents),
        'cus_paid_amount': Money.fromCents(cart.paidCents),
        'cus_balance': Money.fromCents(cart.changeCents),
        'transaction_date': DbDate.now(),
        'type': type,
        'method1': tenders.isNotEmpty ? Money.fromCents(tenders[0].amountCents).toStringAsFixed(2) : '0.0',
        'method2': tenders.length > 1 ? Money.fromCents(tenders[1].amountCents).toStringAsFixed(2) : '0.0',
        'method1Id': tenders.isNotEmpty ? tenders[0].typeId : null,
        'method2Id': tenders.length > 1 ? tenders[1].typeId : null,
        // Holds the shift id; reports group transactions by it.
        'user_id': '$logId',
        'item_count': cart.itemCount,
      });

      final batch = txn.batch();
      for (final line in cart.lines) {
        final item = line.item;
        final amount = Money.fromCents(line.amountCents * sign);
        batch.insert('TransactionItems', {
          'transaction_id': transactionId,
          'item': item.description,
          'quantity': line.quantity,
          'price': Money.fromCents(item.priceCents),
          'amount': amount,
          'dep_id': item.departmentId,
          'vat': item.vat,
          'promo': '',
          'promo_val': 0.0,
        });
        batch.insert('SoldItems', {
          'TranId': transactionId,
          'Price': Money.fromCents(item.priceCents),
          'Qty': line.quantity,
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
}
