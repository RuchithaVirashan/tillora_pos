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

  /// Marks where the shift's void and no sale counts start again.
  static const voidReset = 'voidreset';

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
  /// Records before the shift's latest [voidReset] no longer count; they
  /// stay in the log.
  Future<int> countForShift(String type, int logId) async {
    final rows = await _db.rawQuery('''
SELECT COUNT(*) AS n FROM posRecords
 WHERE Rec_Type = ?1 AND LogId = ?2
   AND Rec_Id > COALESCE((SELECT MAX(Rec_Id) FROM posRecords WHERE Rec_Type = ?3 AND LogId = ?2), 0)''', [type, logId, voidReset]);
    return rows.first['n'] as int;
  }

  /// Starts the shift's void and no sale counts again from zero.
  Future<void> resetCounts({required int logId, required String approvedBy}) =>
      record(type: voidReset, reason: 'Counts reset, approved by $approvedBy', logId: logId);
}
