import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/utils/db_date.dart';

/// Shifts live in `logDetails`. `Status` is '1' while the shift is open.
class ShiftDao {
  ShiftDao(this._db);

  final Database _db;

  static const _open = '1';
  static const _closed = '0';

  /// The user's open shift, if any. If an older shift was left open (app
  /// crash), it is closed first and the user starts fresh.
  Future<Map<String, Object?>?> findOpenShift(int userId) async {
    final rows = await _db.query(
      'logDetails',
      where: 'Userid = ? AND Status = ?',
      whereArgs: ['$userId', _open],
      orderBy: 'LogId DESC',
    );
    if (rows.isEmpty) return null;

    final latest = await _db.rawQuery('SELECT MAX(LogId) AS id FROM logDetails WHERE Userid = ?', ['$userId']);
    final latestId = latest.first['id'] as int?;
    final open = rows.first;
    if (open['LogId'] != latestId || rows.length > 1) {
      await _db.rawUpdate(
        "UPDATE logDetails SET Status = ?, cloudSync = 0, "
        "ShiftEnd = CASE WHEN ShiftEnd = '' THEN ? ELSE ShiftEnd END "
        "WHERE Userid = ? AND Status = ? AND LogId != ?",
        [_closed, DbDate.now(), '$userId', _open, latestId],
      );
      return open['LogId'] == latestId ? open : null;
    }
    return open;
  }

  Future<int> startShift(int userId, DateTime at) => _db.insert('logDetails', {
    'Userid': '$userId',
    'ShiftStarted': DbDate.format(at),
    'ShiftEnd': '',
    'Status': _open,
    'drawfloat': 0.0,
    'dup_prints': 0,
  });

  Future<Map<String, Object?>?> byId(int logId) async {
    final rows = await _db.query('logDetails', where: 'LogId = ?', whereArgs: [logId], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> closeShift(int logId, {required double drawerFloat}) => _db.update(
    'logDetails',
    {'Status': _closed, 'ShiftEnd': DbDate.now(), 'drawfloat': drawerFloat, 'cloudSync': 0},
    where: 'LogId = ?',
    whereArgs: [logId],
  );
}
