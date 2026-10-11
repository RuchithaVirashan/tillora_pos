import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide DatabaseException;

import '../../../../core/errors/exceptions.dart';
import '../../../../infrastructure/database/dao/shift_dao.dart';

class AuthLocalDataSource {
  AuthLocalDataSource(this._db, this._shifts);

  final Database _db;
  final ShiftDao _shifts;

  /// Case and spaces are ignored, matched in SQL.
  Future<Map<String, Object?>?> findUser(String userName) async {
    try {
      final key = userName.toLowerCase().replaceAll(' ', '');
      final rows = await _db.rawQuery(
        "SELECT id, userName, password, roleId FROM userDetails WHERE REPLACE(LOWER(userName), ' ', '') = ? LIMIT 1",
        [key],
      );
      return rows.isEmpty ? null : rows.first;
    } catch (e) {
      throw DatabaseException('Could not read users', cause: e);
    }
  }

  Future<void> updatePassword(int userId, String stored) =>
      _db.update('userDetails', {'password': stored, 'cloudSync': 0}, where: 'id = ?', whereArgs: [userId]);

  /// The user's own access row, else their role's template row (userId 0).
  Future<String?> accessJson(int userId, int roleId) async {
    final rows = await _db.rawQuery(
      'SELECT access FROM userAccess WHERE userId = ? OR (userId = 0 AND roleId = ?) ORDER BY userId DESC LIMIT 1',
      [userId, roleId],
    );
    return rows.isEmpty ? null : rows.first['access'] as String;
  }

  Future<Map<String, Object?>?> openShift(int userId) => _shifts.findOpenShift(userId);

  Future<int> startShift(int userId, DateTime at) => _shifts.startShift(userId, at);
}
