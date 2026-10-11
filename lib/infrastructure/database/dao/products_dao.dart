import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Product lookups shared by the cart and price check.
class ProductsDao {
  ProductsDao(this._db);

  final Database _db;

  static const _columns =
      'id, description, barcode, price, departmentId, stock, vat, ageRefusal, expiryDate, caseBarcode, pluCode';

  /// [_columns] qualified with the products alias, for joins.
  static final _pColumns = _columns.split(', ').map((c) => 'p.$c').join(', ');

  /// Resolves a scanned code to one sellable row, in this order:
  /// main barcode, secondary barcode (with its own price), lottery, news.
  /// One query against `COLLATE NOCASE` indexes.
  Future<Map<String, Object?>?> findByBarcode(String barcode) async {
    final code = barcode.trim();
    if (code.isEmpty) return null;
    final rows = await _db.rawQuery('''
SELECT * FROM (
  SELECT $_columns, 'product' AS source, 0 AS rank
    FROM products WHERE barcode = ?1 COLLATE NOCASE
  UNION ALL
  SELECT p.id, p.description, p.barcode, s.price, p.departmentId, p.stock, p.vat, p.ageRefusal,
         p.expiryDate, p.caseBarcode, p.pluCode, 'product', 1
    FROM secondaryBarcode s JOIN products p ON p.id = s.prodId
   WHERE s.barcode = ?1 COLLATE NOCASE
  UNION ALL
  SELECT id, description, barcode, price, departmentId, NULL, vat, ageRefusal, NULL, NULL, NULL, 'lottery', 2
    FROM lottery WHERE barcode = ?1 COLLATE NOCASE
  UNION ALL
  SELECT id, description, barcode, price, departmentId, stock, vat, ageRefusal, NULL, caseBarcode, pluCode, 'news', 3
    FROM newsAndMagazines WHERE barcode = ?1 COLLATE NOCASE
) ORDER BY rank LIMIT 1''', [code]);
    return rows.isEmpty ? null : rows.first;
  }

  /// Price check search: exact barcode or PLU, else description contains.
  Future<List<Map<String, Object?>>> search(String query, {int limit = 20}) {
    final q = query.trim();
    return _db.rawQuery('''
SELECT $_pColumns, d.name AS departmentName
  FROM products p LEFT JOIN departments d ON d.id = p.departmentId
 WHERE p.barcode = ?1 COLLATE NOCASE OR p.pluCode = ?1 OR p.description LIKE ?2
 ORDER BY (p.barcode = ?1 COLLATE NOCASE) DESC, p.description
 LIMIT ?3''', [q, '%$q%', limit]);
  }

  /// Products sold by weight (`caseBarcode = 'weight'`), price per kg.
  Future<List<Map<String, Object?>>> weighedProducts(String query, {int limit = 30}) {
    final q = query.trim();
    return _db.rawQuery(
      "SELECT $_columns FROM products WHERE caseBarcode = 'weight' "
      "AND (?1 = '' OR barcode = ?1 COLLATE NOCASE OR description LIKE ?2) ORDER BY description LIMIT ?3",
      [q, '%$q%', limit],
    );
  }

  /// Non-barcode items (department keys) first, then quick item products.
  /// A non-barcode item with price 0 is sold at a typed price.
  Future<List<Map<String, Object?>>> quickItems({int limit = 500}) => _db.rawQuery('''
SELECT * FROM (
  SELECT $_columns, 'product' AS source, 1 AS rank FROM products WHERE isQuickitem = 1
  UNION ALL
  SELECT NULL, description, CAST(item_id AS TEXT), price, depid, NULL, vat, ageRefusal, NULL, NULL, NULL, 'manual', 0
    FROM nonBarcodeItems WHERE item_id NOT IN (888888, 999999) AND depid != 0
) ORDER BY rank, description LIMIT ?''', [limit]);

  Future<List<Map<String, Object?>>> departments() =>
      _db.query('departments', columns: ['id', 'name', 'vat', 'ageRefusal'], orderBy: 'name');

  /// Updates a price and keeps the previous one in `wasPrice`.
  Future<void> updatePrice(int productId, double newPrice) => _db.rawUpdate(
    'UPDATE products SET wasPrice = price, price = ?, priceUpdated = 1, cloudSync = 0 WHERE id = ?',
    [newPrice, productId],
  );

  Future<void> setExpiry(int productId, String? expiryDate) =>
      _db.update('products', {'expiryDate': expiryDate, 'cloudSync': 0}, where: 'id = ?', whereArgs: [productId]);
}
