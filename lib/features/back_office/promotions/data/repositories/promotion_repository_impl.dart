import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/money.dart';
import '../../domain/entities/promotion.dart';
import '../../domain/repositories/promotion_repository.dart';

class PromotionRepositoryImpl implements PromotionRepository {
  PromotionRepositoryImpl(this._db);

  final Database _db;

  /// `promotions.startDate` / `endDate` format.
  static final _day = DateFormat('yyyy-MM-dd');

  @override
  Future<Result<List<PromotionSummary>>> promotions(String query) => _guard(() async {
    final rows = await _db.rawQuery('''
SELECT p.*, (SELECT COUNT(*) FROM promotionItems i WHERE i.promotionId = p.id) AS itemCount
  FROM promotions p
 WHERE ?1 = '' OR CAST(p.id AS TEXT) = ?1 OR p.description LIKE ?2
    OR EXISTS (SELECT 1 FROM promotionItems i JOIN products pr ON pr.id = i.productId
                WHERE i.promotionId = p.id AND pr.barcode = ?1 COLLATE NOCASE)
 ORDER BY p.id DESC''', [query, '%$query%']);
    return [
      for (final r in rows)
        (
          id: r['id'] as int,
          description: r['description'] as String,
          type: PromoType.fromLabel(r['promotionType'] as String),
          amountCents: Money.toCents((r['amount'] as num?) ?? 0),
          start: _parse(r['startDate']),
          end: _parse(r['endDate']),
          itemCount: r['itemCount'] as int,
        ),
    ];
  });

  @override
  Future<Result<Promotion?>> byId(int id) => _guard(() async {
    final rows = await _db.query('promotions', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final r = rows.first;
    final items = await _db.rawQuery('''
SELECT i.groupId, p.id, p.barcode, p.description, p.price
  FROM promotionItems i JOIN products p ON p.id = i.productId
 WHERE i.promotionId = ? ORDER BY i.id''', [id]);
    final groups = <int, List<PromoProduct>>{};
    for (final i in items) {
      groups.putIfAbsent((i['groupId'] as int?) ?? 1, () => []).add(_product(i));
    }
    return Promotion(
      id: id,
      description: r['description'] as String,
      type: PromoType.fromLabel(r['promotionType'] as String),
      start: _parse(r['startDate']),
      end: _parse(r['endDate']),
      qty: int.tryParse('${r['qty']}') ?? 1,
      amountCents: Money.toCents((r['amount'] as num?) ?? 0),
      groups: groups,
    );
  });

  @override
  Future<Result<PromoProduct?>> productByBarcode(String barcode) => _guard(() async {
    final rows = await _db.rawQuery('''
SELECT id, barcode, description, price FROM products WHERE barcode = ?1 COLLATE NOCASE
UNION ALL
SELECT p.id, p.barcode, p.description, p.price
  FROM secondaryBarcode s JOIN products p ON p.id = s.prodId WHERE s.barcode = ?1 COLLATE NOCASE
LIMIT 1''', [barcode]);
    return rows.isEmpty ? null : _product(rows.first);
  });

  @override
  Future<Result<List<PromoClash>>> clashes(Iterable<int> productIds, DateTime start, DateTime end, {int? exceptId}) => _guard(() async {
    final ids = productIds.toList();
    if (ids.isEmpty) return const <PromoClash>[];
    final rows = await _db.rawQuery('''
SELECT pr.description AS product, p.description AS promotion
  FROM promotionItems i
  JOIN promotions p ON p.id = i.promotionId
  JOIN products pr ON pr.id = i.productId
 WHERE i.productId IN (${List.filled(ids.length, '?').join(',')})
   AND p.id != ? AND p.startDate <= ? AND p.endDate >= ?''', [...ids, exceptId ?? -1, _day.format(end), _day.format(start)]);
    return [for (final r in rows) (product: r['product'] as String, promotion: r['promotion'] as String)];
  });

  @override
  Future<Result<bool>> exists(String description, DateTime start, DateTime end) => _guard(() async {
    final rows = await _db.query(
      'promotions',
      columns: ['id'],
      where: 'description = ? AND startDate = ? AND endDate = ?',
      whereArgs: [description, _day.format(start), _day.format(end)],
      limit: 1,
    );
    return rows.isNotEmpty;
  });

  @override
  Future<Result<int>> save(Promotion p) => _guard(() => _db.transaction((txn) async {
    final values = {
      'description': p.description.trim(),
      'startDate': _day.format(p.start),
      'endDate': _day.format(p.end),
      'promotionType': p.type.label,
      'qty': '${p.qty}',
      'amount': Money.fromCents(p.amountCents),
      'cloudSync': 0,
    };
    final int id;
    if (p.id == null) {
      id = await txn.insert('promotions', values);
    } else {
      id = p.id!;
      await txn.update('promotions', values, where: 'id = ?', whereArgs: [id]);
      await txn.delete('promotionItems', where: 'promotionId = ?', whereArgs: [id]);
    }
    final batch = txn.batch();
    for (final MapEntry(key: group, value: products) in p.groups.entries) {
      for (final product in products) {
        batch.insert('promotionItems', {'promotionId': id, 'productId': product.productId, 'groupId': group});
      }
    }
    await batch.commit(noResult: true);
    return id;
  }));

  @override
  Future<Result<void>> delete(int id) => _guard(() => _db.transaction((txn) async {
    await txn.delete('promotionItems', where: 'promotionId = ?', whereArgs: [id]);
    await txn.delete('promotions', where: 'id = ?', whereArgs: [id]);
  }));

  @override
  Future<Result<PromoSheet>> readSheet(Uint8List bytes) async {
    try {
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables.values.firstOrNull;
      if (sheet == null) return const Err(ValidationFailure('No sheets found in the spreadsheet'));
      final rows = sheet.rows;
      String cell(List<Data?> row, int i) => i < row.length ? _text(row[i]?.value) : '';

      DateTime? start, end;
      if (rows.length > 3) {
        final range = cell(rows[3], 3).split('-');
        if (range.length == 2) {
          final f = DateFormat('dd/MM/yyyy');
          start = f.tryParseStrict(range[0].trim());
          end = f.tryParseStrict(range[1].trim());
        }
      }
      return Ok((
        start: start,
        end: end,
        rows: [
          for (final row in rows.skip(1))
            if ((description: cell(row, 5), barcode: cell(row, 8)) case final r when r.description.isNotEmpty && r.barcode.isNotEmpty) r,
        ],
      ));
    } catch (e) {
      return Err(ValidationFailure('Could not read the file: $e'));
    }
  }

  /// Whole numbers stored as doubles (barcodes) lose their ".0".
  static String _text(CellValue? v) => switch (v) {
    null => '',
    DoubleCellValue(:final value) when value == value.truncateToDouble() => value.toInt().toString(),
    _ => v.toString().trim(),
  };

  static DateTime _parse(Object? v) => DateTime.tryParse('$v') ?? DateTime(2000);

  static PromoProduct _product(Map<String, Object?> r) => PromoProduct(
    productId: r['id'] as int,
    barcode: r['barcode'] as String,
    description: r['description'] as String,
    priceCents: Money.toCents(r['price'] as num),
  );

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }
}
