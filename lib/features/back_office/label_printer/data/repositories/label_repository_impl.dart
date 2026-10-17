import 'package:printing/printing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../infrastructure/hardware/hardware_registry.dart';
import '../../domain/entities/label_product.dart';
import '../../domain/repositories/label_repository.dart';
import '../datasources/label_pdf.dart';

class LabelRepositoryImpl implements LabelRepository {
  /// [rollPrinter] targets the label printer set in System Configuration.
  LabelRepositoryImpl(this._db, this._rollPrinter);

  final Database _db;
  final SystemPrinter _rollPrinter;

  static const _columns = 'p.id, p.barcode, p.description, p.price, p.wasPrice, p.pluCode';

  static String _ofType(LabelType type) =>
      type == LabelType.weight ? "p.caseBarcode = 'weight'" : "(p.caseBarcode IS NULL OR p.caseBarcode != 'weight')";

  @override
  Future<Result<List<LabelProduct>>> products(LabelType type, {required int departmentId}) => _guard(() async {
    final rows = await _db.rawQuery(
      'SELECT $_columns FROM products p WHERE p.departmentId = ? AND ${_ofType(type)} ORDER BY p.description',
      [departmentId],
    );
    return rows.map(_fromRow).toList();
  });

  @override
  Future<Result<LabelProduct?>> find(String code, LabelType type) => _guard(() async {
    final rows = await _db.rawQuery('''
SELECT $_columns FROM products p
 WHERE ${_ofType(type)}
   AND (p.barcode = ?1 COLLATE NOCASE OR p.pluCode = ?1
        OR EXISTS (SELECT 1 FROM secondaryBarcode s WHERE s.prodId = p.id AND s.barcode = ?1 COLLATE NOCASE))
 LIMIT 1''', [code]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  });

  @override
  Future<Result<void>> print(List<LabelLine> lines, LabelType type, LabelFormat format) => _guard(failure: HardwareFailure.new, () async {
    final bytes = await LabelPdf.build(lines, type, format);
    final name = '${type.label}s';
    switch (format) {
      case LabelFormat.roll:
        await _rollPrinter.printPdf(bytes, name: name);
      case LabelFormat.sheet:
        // Sheets go to an office printer, so let staff choose it.
        await Printing.layoutPdf(name: name, onLayout: (_) async => bytes);
    }
  });

  static LabelProduct _fromRow(Map<String, Object?> r) {
    final price = Money.toCents(r['price'] as num);
    final was = r['wasPrice'] == null ? null : Money.toCents(r['wasPrice'] as num);
    final plu = r['pluCode'] as String?;
    return LabelProduct(
      productId: r['id'] as int,
      barcode: r['barcode'] as String,
      description: r['description'] as String,
      priceCents: price,
      wasPriceCents: was != null && was > price ? was : null,
      pluCode: plu == null || plu.trim().isEmpty ? null : plu.trim(),
    );
  }

  Future<Result<T>> _guard<T>(Future<T> Function() run, {Failure Function(String) failure = DatabaseFailure.new}) async {
    try {
      return Ok(await run());
    } catch (e) {
      return Err(failure('$e'));
    }
  }
}
