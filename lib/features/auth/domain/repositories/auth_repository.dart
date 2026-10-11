import '../../../../core/errors/result.dart';
import '../../../../core/session/user_session.dart';

abstract interface class AuthRepository {
  /// Checks the user name and password. Fails with [PermissionFailure] for a
  /// wrong password, [ValidationFailure] for an unknown user.
  Future<Result<UserSession>> authenticate({required String userName, required String password});

  /// Resumes the user's open shift or starts a new one.
  Future<Result<UserSession>> openShift(UserSession session);
}
