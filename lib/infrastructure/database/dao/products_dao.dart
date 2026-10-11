import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Product lookups shared by the cart and price check.
class ProductsDao {
  ProductsDao(this._db);

  final Database _db;

  static const _columns =
      'id, description, barcode, price, departmentId, stock, vat, ageRefusal, expiryDate, caseBarcode, pluCode';

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
SELECT p.$_columns, d.name AS departmentName
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

  Future<List<Map<String, Object?>>> quickItems({int limit = 40}) => _db.query(
    'products',
    columns: _columns.split(', '),
    where: 'isQuickitem = 1',
    orderBy: 'description',
    limit: limit,
  );

  /// Updates a price and keeps the previous one in `wasPrice`.
  Future<void> updatePrice(int productId, double newPrice) => _db.rawUpdate(
    'UPDATE products SET wasPrice = price, price = ?, priceUpdated = 1, cloudSync = 0 WHERE id = ?',
    [newPrice, productId],
  );

  Future<void> setExpiry(int productId, String? expiryDate) =>
      _db.update('products', {'expiryDate': expiryDate, 'cloudSync': 0}, where: 'id = ?', whereArgs: [productId]);
}
