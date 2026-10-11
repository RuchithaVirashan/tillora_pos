import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/security/password_hasher.dart';
import '../../../../core/session/access_rights.dart';
import '../../../../core/session/user_session.dart';
import '../../../../core/utils/db_date.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._local);

  final AuthLocalDataSource _local;

  @override
  Future<Result<UserSession>> authenticate({required String userName, required String password}) async {
    try {
      final user = await _local.findUser(userName);
      if (user == null) return const Err(ValidationFailure('User not found'));

      final id = user['id'] as int;
      final name = user['userName'] as String;
      final stored = user['password'] as String;
      if (!PasswordHasher.verify(password, userName: name, stored: stored)) {
        return const Err(PermissionFailure('Invalid user name or password'));
      }
      if (!PasswordHasher.isHashed(stored)) {
        await _local.updatePassword(id, PasswordHasher.hash(password, userName: name));
      }

      final roleId = user['roleId'] as int;
      final json = await _local.accessJson(id, roleId);
      return Ok(UserSession(
        userId: id,
        userName: name,
        roleId: roleId,
        access: json == null ? AccessRights.none : AccessRights.fromJson(json),
        loggedInAt: DateTime.now(),
      ));
    } catch (e) {
      return Err(DatabaseFailure('Login failed: $e'));
    }
  }

  @override
  Future<Result<UserSession>> openShift(UserSession session) async {
    try {
      final open = await _local.openShift(session.userId);
      if (open != null) {
        final started = DbDate.tryParse(open['ShiftStarted'] as String?) ?? DateTime.now();
        return Ok(session.withShift(open['LogId'] as int, started));
      }
      final now = DateTime.now();
      final logId = await _local.startShift(session.userId, now);
      return Ok(session.withShift(logId, now));
    } catch (e) {
      return Err(DatabaseFailure('Could not start the shift: $e'));
    }
  }
}
