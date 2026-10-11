import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/session/access_rights.dart';
import '../../domain/repositories/role_access_repository.dart';

class RoleAccessRepositoryImpl implements RoleAccessRepository {
  RoleAccessRepositoryImpl(this._db);

  final Database _db;

  @override
  Future<Result<List<AccessUser>>> users() => _guard(() async {
    final rows = await _db.query('userDetails', columns: ['id', 'userName', 'roleId'], orderBy: 'roleId, userName COLLATE NOCASE');
    return [for (final r in rows) (id: r['id'] as int, userName: r['userName'] as String, roleId: r['roleId'] as int)];
  });

  /// Same lookup as login: the user's own row, else the role template.
  @override
  Future<Result<AccessRights>> accessFor(AccessUser user) => _guard(() async {
    final rows = await _db.rawQuery(
      'SELECT access FROM userAccess WHERE userId = ? OR (userId = 0 AND roleId = ?) ORDER BY userId DESC LIMIT 1',
      [user.id, user.roleId],
    );
    return rows.isEmpty ? AccessRights.none : AccessRights.fromJson(rows.first['access'] as String);
  });

  @override
  Future<Result<void>> save(AccessUser user, AccessRights access) => _guard(() async {
    final values = {'userName': user.userName, 'roleId': user.roleId, 'access': access.toJson(), 'cloudSync': 0};
    final updated = await _db.update('userAccess', values, where: 'userId = ?', whereArgs: [user.id]);
    if (updated == 0) await _db.insert('userAccess', {'userId': user.id, ...values});
  });

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }
}
