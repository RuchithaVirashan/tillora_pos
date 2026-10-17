import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/db_date.dart';
import '../../../../../core/utils/money.dart';
import '../../domain/entities/barcode_product.dart';
import '../../domain/repositories/barcode_product_repository.dart';

class BarcodeProductRepositoryImpl implements BarcodeProductRepository {
  BarcodeProductRepositoryImpl(this._db);

  final Database _db;

  static const _select = '''
SELECT p.*, d.name AS departmentName,
       (SELECT s.barcode FROM secondaryBarcode s WHERE s.prodId = p.id ORDER BY s.id LIMIT 1) AS secondary,
       EXISTS (SELECT 1 FROM promotionItems i WHERE i.productId = p.id) AS inPromotion
  FROM products p LEFT JOIN departments d ON d.id = p.departmentId''';

  static const _notWeighed = "(p.caseBarcode IS NULL OR p.caseBarcode != 'weight')";

  @override
  Future<Result<List<BarcodeProduct>>> products(String query, {int limit = 500}) => _guard(() async {
    final rows = await _db.rawQuery('''
$_select
 WHERE $_notWeighed
   AND (?1 = '' OR p.barcode = ?1 COLLATE NOCASE OR p.description LIKE ?2
        OR EXISTS (SELECT 1 FROM secondaryBarcode s WHERE s.prodId = p.id AND s.barcode = ?1 COLLATE NOCASE))
 ORDER BY (p.barcode = ?1 COLLATE NOCASE) DESC, p.description
 LIMIT ?3''', [query, '%$query%', limit]);
    return rows.map(_fromRow).toList();
  });

  @override
  Future<Result<BarcodeProduct?>> byId(int id) => _guard(() async {
    final rows = await _db.rawQuery('$_select WHERE p.id = ?', [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  });

  @override
  Future<Result<String?>> barcodeOwner(String code, {int? exceptId}) => _guard(() async {
    final rows = await _db.rawQuery('''
SELECT description FROM products
 WHERE (barcode = ?1 COLLATE NOCASE OR caseBarcode = ?1 COLLATE NOCASE) AND id != ?2
UNION ALL
SELECT p.description FROM secondaryBarcode s JOIN products p ON p.id = s.prodId
 WHERE s.barcode = ?1 COLLATE NOCASE AND s.prodId != ?2
LIMIT 1''', [code, exceptId ?? -1]);
    return rows.isEmpty ? null : rows.first['description'] as String;
  });

  @override
  Future<Result<int>> save(BarcodeProduct p) => _guard(() => _db.transaction((txn) async {
    final values = <String, Object?>{
      'description': p.description.trim(),
      'barcode': p.barcode,
      'departmentId': p.departmentId,
      'subDeptId': p.subDepartmentId,
      'vat': p.vat,
      'ageRefusal': p.ageLimit,
      'isQuickitem': p.quickItem ? 1 : 0,
      'caseBarcode': _blankToNull(p.caseBarcode),
      'upc': '${p.unitsPerCase}',
      'cpc': Money.fromCents(p.costPerCaseCents),
      'costPrice': Money.fromCents(p.costPriceCents),
      'margin': Money.fromCents(p.marginCents),
      'cloudSync': 0,
    };
    final price = Money.fromCents(p.priceCents);
    final int id;
    if (p.id == null) {
      id = await txn.insert('products', {...values, 'price': price, 'stock': p.stock});
    } else {
      id = p.id!;
      final old = (await txn.query('products', columns: ['price'], where: 'id = ?', whereArgs: [id])).first['price'] as num;
      final priceChanged = Money.toCents(old) != p.priceCents;
      await txn.update(
        'products',
        {...values, 'price': price, if (priceChanged) ...{'wasPrice': old, 'priceUpdated': 1}},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await _saveSecondary(txn, id, _blankToNull(p.secondaryBarcode), price);
    return id;
  }));

  /// Keeps one secondary barcode in step with the form: adds, changes or
  /// removes the first one. Its price follows the product price.
  Future<void> _saveSecondary(Transaction txn, int productId, String? code, double price) async {
    final existing = await txn.query('secondaryBarcode', columns: ['id'], where: 'prodId = ?', whereArgs: [productId], orderBy: 'id', limit: 1);
    final existingId = existing.firstOrNull?['id'] as int?;
    if (code == null) {
      if (existingId != null) await txn.delete('secondaryBarcode', where: 'id = ?', whereArgs: [existingId]);
    } else if (existingId == null) {
      await txn.insert('secondaryBarcode', {'prodId': productId, 'barcode': code, 'price': price});
    } else {
      await txn.update('secondaryBarcode', {'barcode': code, 'price': price, 'cloudSync': 0}, where: 'id = ?', whereArgs: [existingId]);
    }
  }

  @override
  Future<Result<void>> delete(int id) => _guard(() => _db.transaction((txn) async {
    await txn.delete('secondaryBarcode', where: 'prodId = ?', whereArgs: [id]);
    await txn.delete('products', where: 'id = ?', whereArgs: [id]);
  }));

  @override
  Future<Result<void>> stockIn(List<StockInLine> lines) => _guard(() => _db.transaction((txn) async {
    final at = DbDate.now();
    for (final line in lines) {
      final before = (await txn.query('products', columns: ['stock'], where: 'id = ?', whereArgs: [line.productId])).first['stock'] as int;
      final after = before + line.quantity;
      await txn.update('products', {'stock': after, 'cloudSync': 0}, where: 'id = ?', whereArgs: [line.productId]);
      await txn.insert('stockAdjustment', {
        'barcode': line.barcode,
        'beforeStock': before,
        'afterStock': after,
        'adjustmentQuantity': line.quantity,
        'adjustmentType': 'Stock In',
        'adjustedAt': at,
      });
    }
  }));

  static String? _blankToNull(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();

  static BarcodeProduct _fromRow(Map<String, Object?> r) => BarcodeProduct(
    id: r['id'] as int,
    barcode: r['barcode'] as String,
    description: r['description'] as String,
    priceCents: Money.toCents(r['price'] as num),
    departmentId: r['departmentId'] as int,
    departmentName: r['departmentName'] as String? ?? '',
    subDepartmentId: (r['subDeptId'] as num?)?.toInt(),
    vat: (r['vat'] as num).toDouble(),
    stock: r['stock'] as int,
    ageLimit: (r['ageRefusal'] as num?)?.toInt() ?? 0,
    secondaryBarcode: r['secondary'] as String?,
    caseBarcode: r['caseBarcode'] as String?,
    unitsPerCase: int.tryParse('${r['upc'] ?? ''}') ?? 1,
    costPerCaseCents: Money.toCents((r['cpc'] as num?) ?? 0),
    quickItem: r['isQuickitem'] == 1,
    inPromotion: r['inPromotion'] == 1,
  );

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }
}
