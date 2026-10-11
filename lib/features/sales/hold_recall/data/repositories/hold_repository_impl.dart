import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/db_date.dart';
import '../../../../../core/utils/money.dart';
import '../../../cart/domain/entities/cart.dart';
import '../../../cart/domain/entities/sellable_item.dart';
import '../../domain/entities/held_sale.dart';
import '../../domain/repositories/hold_repository.dart';

/// Held sales live in `saleOnHold`, one row per hold, lines as JSON.
class HoldRepositoryImpl implements HoldRepository {
  HoldRepositoryImpl(this._db);

  final Database _db;

  @override
  Future<Result<List<HeldSale>>> heldSales(int logId) => _guard(() async {
    final rows = await _db.query('saleOnHold', where: 'logid = ?', whereArgs: [logId], orderBy: 'id DESC');
    return [
      for (final r in rows)
        HeldSale(
          id: r['id'] as int,
          heldAt: DbDate.tryParse(r['hold_datetime'] as String?) ?? DateTime.now(),
          itemCount: r['item_count'] as int,
          totalCents: Money.toCents(r['total'] as num),
        ),
    ];
  });

  @override
  Future<Result<void>> hold(List<CartLine> lines, {required int logId}) => _guard(() async {
    final total = lines.fold<int>(0, (s, l) => s + l.amountCents);
    await _db.insert('saleOnHold', {
      'hold_datetime': DbDate.now(),
      'items': jsonEncode([for (final l in lines) _encode(l)]),
      'total': Money.fromCents(total),
      'item_count': lines.fold<int>(0, (n, l) => n + l.quantity),
      'logid': logId,
    });
  });

  @override
  Future<Result<List<CartLine>>> recall(int holdId) => _guard(() => _db.transaction((txn) async {
    final rows = await txn.query('saleOnHold', columns: ['items'], where: 'id = ?', whereArgs: [holdId]);
    await txn.delete('saleOnHold', where: 'id = ?', whereArgs: [holdId]);
    return rows.isEmpty ? <CartLine>[] : _decode(rows.first['items'] as String);
  }));

  @override
  Future<Result<List<CartLine>>> recallAll(int logId) => _guard(() => _db.transaction((txn) async {
    final rows = await txn.query('saleOnHold', columns: ['items'], where: 'logid = ?', whereArgs: [logId], orderBy: 'id');
    await txn.delete('saleOnHold', where: 'logid = ?', whereArgs: [logId]);
    return [for (final r in rows) ..._decode(r['items'] as String)];
  }));

  /// Line fields plus product and department ids.
  static Map<String, Object?> _encode(CartLine l) => {
    'item_name': l.item.description,
    'quantity': l.quantity,
    'price': Money.fromCents(l.item.priceCents),
    'amount': Money.fromCents(l.amountCents),
    'cloudSync': 0,
    'barcode': l.item.barcode,
    'productId': l.item.productId,
    'departmentId': l.item.departmentId,
    'departmentName': l.item.departmentName,
    'vat': l.item.vat,
    'source': l.item.source.name,
  };

  static List<CartLine> _decode(String json) => [
    for (final m in (jsonDecode(json) as List).cast<Map<String, dynamic>>())
      CartLine(
        quantity: (m['quantity'] as num).toInt(),
        item: SellableItem(
          productId: m['productId'] as int?,
          description: m['item_name'] as String,
          barcode: (m['barcode'] as String?) ?? '',
          priceCents: Money.toCents(m['price'] as num),
          departmentId: (m['departmentId'] as num?)?.toInt() ?? 0,
          departmentName: (m['departmentName'] as String?) ?? '',
          vat: (m['vat'] as num?)?.toDouble() ?? 0,
          source: ItemSource.values.asNameMap()[m['source']] ?? ItemSource.manual,
        ),
      ),
  ];

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }
}
