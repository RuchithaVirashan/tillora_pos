import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/utils/db_date.dart';

/// Audit records for no sale, voids and age refusals (`posRecords`), and the
/// reason lists staff pick from (`posMessages`).
class PosRecordsDao {
  PosRecordsDao(this._db);

  final Database _db;

  /// `posMessages.parameter` / `posRecords.Rec_Type` values.
  static const noSale = 'nosale';
  static const voidLine = 'voiditem';
  static const voidSale = 'voidsale';
  static const ageRefusal = 'agerefusal';

  Future<List<String>> reasons(String type) async {
    final rows = await _db.query('posMessages', columns: ['value'], where: 'parameter = ?', whereArgs: [type], orderBy: 'mid');
    return [for (final r in rows) r['value'] as String];
  }

  Future<void> record({
    required String type,
    required String reason,
    required int logId,
    List<Map<String, Object?>> items = const [],
  }) => _db.insert('posRecords', {
    'Rec_Type': type,
    'Rec_Date': DbDate.now(),
    'Record': reason,
    'LogId': logId,
    'Rec_Item': jsonEncode(items),
    'reason': reason,
  });

  /// How many of [type] this shift has used, for the role's daily limit.
  Future<int> countForShift(String type, int logId) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS n FROM posRecords WHERE Rec_Type = ? AND LogId = ?',
      [type, logId],
    );
    return rows.first['n'] as int;
  }
}
