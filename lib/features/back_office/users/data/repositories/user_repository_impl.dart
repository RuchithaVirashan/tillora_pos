import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/security/password_hasher.dart';
import '../../domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._db);

  final Database _db;

  @override
  Future<Result<List<StaffUser>>> users() => _guard(() async {
    final rows = await _db.rawQuery(
      'SELECT u.id, u.userName, u.roleId, '
      "EXISTS (SELECT 1 FROM logDetails l WHERE l.Userid = CAST(u.id AS TEXT) AND l.Status = '1') AS onShift "
      'FROM userDetails u ORDER BY u.userName COLLATE NOCASE',
    );
    return [
      for (final r in rows) (id: r['id'] as int, userName: r['userName'] as String, roleId: r['roleId'] as int, onShift: r['onShift'] == 1),
    ];
  });

  @override
  Future<Result<int>> add({required String userName, required String password, required int roleId}) => _guard(
    () => _db.transaction((txn) async {
      final id = await txn.insert('userDetails', {
        'userName': userName,
        'password': PasswordHasher.hash(password, userName: userName),
        'roleId': roleId,
      });
      await _copyRoleAccess(txn, userId: id, userName: userName, roleId: roleId);
      return id;
    }),
  );

  /// The password hash includes the user name, so renaming a user needs a
  /// new password; the old hash would no longer match.
  @override
  Future<Result<void>> update(int id, {required String userName, String? password, required int roleId, required bool roleChanged}) =>
      _guard(
        () => _db.transaction((txn) async {
          final current = (await txn.query('userDetails', columns: ['userName'], where: 'id = ?', whereArgs: [id])).first;
          final renamed = current['userName'] != userName;
          if (renamed && password == null) {
            throw StateError('Enter a new password when changing the user name');
          }
          await txn.update(
            'userDetails',
            {
              'userName': userName,
              'roleId': roleId,
              'password': ?(password == null ? null : PasswordHasher.hash(password, userName: userName)),
              'cloudSync': 0,
            },
            where: 'id = ?',
            whereArgs: [id],
          );
          if (roleChanged) {
            await txn.delete('userAccess', where: 'userId = ?', whereArgs: [id]);
            await _copyRoleAccess(txn, userId: id, userName: userName, roleId: roleId);
          } else if (renamed) {
            await txn.update('userAccess', {'userName': userName}, where: 'userId = ?', whereArgs: [id]);
          }
        }),
      );

  @override
  Future<Result<void>> delete(int id) => _guard(
    () => _db.transaction((txn) async {
      await txn.delete('userAccess', where: 'userId = ?', whereArgs: [id]);
      await txn.delete('userDetails', where: 'id = ?', whereArgs: [id]);
    }),
  );

  /// Gives the user their own access row, copied from the role template
  /// (userId 0), so Role Access can change it for this user alone.
  static Future<void> _copyRoleAccess(Transaction txn, {required int userId, required String userName, required int roleId}) async {
    final template = await txn.query('userAccess', columns: ['access'], where: 'userId = 0 AND roleId = ?', whereArgs: [roleId], limit: 1);
    if (template.isEmpty) return;
    await txn.insert('userAccess', {'userId': userId, 'userName': userName, 'roleId': roleId, 'access': template.first['access']});
  }

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } on StateError catch (e) {
      return Err(ValidationFailure(e.message));
    } catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }
}
