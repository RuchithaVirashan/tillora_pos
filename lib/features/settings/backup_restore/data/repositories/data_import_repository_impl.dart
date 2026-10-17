import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../infrastructure/database/seed/default_data.dart';
import '../../domain/entities/data_import.dart';
import '../../domain/repositories/data_import_repository.dart';

class DataImportRepositoryImpl implements DataImportRepository {
  DataImportRepositoryImpl(this._db);

  final Database _db;

  /// Problems listed back to staff; the rest are only counted.
  static const _maxProblems = 5;

  @override
  Future<Result<List<List<String>>>> readTable(Uint8List bytes, String extension) async {
    try {
      if (extension == 'xlsx') {
        final sheet = Excel.decodeBytes(bytes).tables.values.firstOrNull;
        if (sheet == null) return const Err(ValidationFailure('No sheets found in the spreadsheet'));
        return Ok([for (final row in sheet.rows) [for (final cell in row) _text(cell?.value)]]);
      }
      // Excel saves CSV with a byte order mark.
      var text = utf8.decode(bytes, allowMalformed: true);
      if (text.startsWith('﻿')) text = text.substring(1);
      return Ok([for (final row in csv.decode(text)) [for (final cell in row) '${cell ?? ''}']]);
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

  @override
  Future<Result<ImportSummary>> insert(ImportTable table, List<Map<String, String>> rows) async {
    try {
      return Ok(await _db.transaction((txn) async {
        final departments = {for (final r in await txn.query('departments', columns: ['id'])) r['id'] as int};
        // Unknown departments go to Default when there is one.
        final fallback = departments.contains(10) ? 10 : (departments.isEmpty ? null : departments.reduce((a, b) => a < b ? a : b));
        var added = 0, existing = 0, invalid = 0;
        final problems = <String>[];
        void bad(int row, String why) {
          invalid++;
          if (problems.length < _maxProblems) problems.add('Row ${row + 2}: $why');
        }

        int? department(String? value) {
          final id = int.tryParse(value ?? '');
          return id != null && departments.contains(id) ? id : fallback;
        }

        double number(String? v, [double fallback = 0]) => double.tryParse((v ?? '').replaceAll(',', '')) ?? fallback;
        int whole(String? v, [int fallback = 0]) => int.tryParse((v ?? '').split('.').first) ?? fallback;
        bool yes(String? v) => ['1', 'true', 'yes', 'y'].contains((v ?? '').toLowerCase());

        switch (table) {
          case ImportTable.products:
            final seen = {for (final r in await txn.query('products', columns: ['barcode'])) (r['barcode'] as String).toLowerCase()};
            for (final (i, r) in rows.indexed) {
              final barcode = r['barcode'] ?? '';
              if (Validators.barcode(barcode) case final error?) {
                bad(i, 'barcode "$barcode": $error');
                continue;
              }
              if ((r['description'] ?? '').isEmpty) {
                bad(i, 'no description');
                continue;
              }
              final price = double.tryParse((r['price'] ?? '').replaceAll(',', ''));
              if (price == null || price < 0) {
                bad(i, 'price "${r['price']}" is not a number');
                continue;
              }
              final dept = department(r['departmentId']);
              if (dept == null) {
                bad(i, 'add a department first');
                continue;
              }
              if (!seen.add(barcode.toLowerCase())) {
                existing++;
                continue;
              }
              await txn.insert('products', {
                'barcode': barcode,
                'description': r['description'],
                'price': price,
                'departmentId': dept,
                'stock': whole(r['stock']),
                'vat': number(r['vat']),
                'ageRefusal': whole(r['ageRefusal']),
                'isQuickitem': yes(r['isQuickitem']) ? 1 : 0,
                'caseBarcode': (r['caseBarcode'] ?? '').isEmpty ? null : r['caseBarcode'],
                'upc': (r['upc'] ?? '').isEmpty ? null : r['upc'],
                'cpc': number(r['cpc']),
                'costPrice': number(r['costPrice']),
                'pluCode': (r['pluCode'] ?? '').isEmpty ? null : r['pluCode'],
              });
              added++;
            }
          case ImportTable.departments:
            final names = {for (final r in await txn.query('departments', columns: ['name'])) (r['name'] as String).toLowerCase()};
            for (final (i, r) in rows.indexed) {
              final name = r['name'] ?? '';
              if (name.isEmpty) {
                bad(i, 'no name');
                continue;
              }
              final id = int.tryParse(r['id'] ?? '');
              if ((id != null && departments.contains(id)) || !names.add(name.toLowerCase())) {
                existing++;
                continue;
              }
              final newId = await txn.insert('departments', {'id': ?id, 'name': name, 'vat': number(r['vat']), 'ageRefusal': whole(r['ageRefusal']), 'isQuickdept': 1});
              departments.add(newId);
              added++;
            }
          case ImportTable.nonBarcode:
            final ids = {for (final r in await txn.query('nonBarcodeItems', columns: ['item_id'])) r['item_id'] as int};
            const reserved = {DefaultData.itemDiscountId, DefaultData.saleDiscountId};
            for (final (i, r) in rows.indexed) {
              final id = int.tryParse(r['item_id'] ?? '');
              if (id == null || id <= 0 || reserved.contains(id)) {
                bad(i, 'item id "${r['item_id']}" is not usable');
                continue;
              }
              if ((r['description'] ?? '').isEmpty) {
                bad(i, 'no description');
                continue;
              }
              final dept = department(r['depid']);
              if (dept == null) {
                bad(i, 'add a department first');
                continue;
              }
              if (!ids.add(id)) {
                existing++;
                continue;
              }
              await txn.insert('nonBarcodeItems', {
                'item_id': id,
                'description': r['description'],
                'price': number(r['price']),
                'depid': dept,
                'vat': number(r['vat']),
                'ageRefusal': whole(r['ageRefusal']),
                'image_path': '',
              });
              added++;
            }
        }
        return (added: added, existing: existing, invalid: invalid, problems: problems);
      }));
    } catch (e) {
      return Err(DatabaseFailure('Import failed, nothing was added: $e'));
    }
  }
}
