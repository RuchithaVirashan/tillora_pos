import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../auth/domain/repositories/auth_repository.dart';
import '../repositories/void_count_repository.dart';

/// Gives a cashier who reached their void or no sale limit a fresh count
/// for this shift. An admin approves it with their own login.
class ResetVoidCounts {
  const ResetVoidCounts(this._auth, this._counts);
  final AuthRepository _auth;
  final VoidCountRepository _counts;

  Future<Result<String>> call({required String userName, required String password, required UserSession session}) async {
    final logId = session.logId;
    if (logId == null) return const Err(ValidationFailure('Open a shift first'));
    if (userName.trim().isEmpty || password.isEmpty) return const Err(ValidationFailure('Please login for reset void counts'));
    final UserSession admin;
    switch (await _auth.authenticate(userName: userName.trim(), password: password)) {
      case Ok(:final value):
        admin = value;
      case Err(:final failure):
        return Err(failure);
    }
    if (admin.roleId != Roles.admin) return const Err(PermissionFailure('Invalid user. Please contact admin'));
    return switch (await _counts.reset(logId: logId, approvedBy: admin.userName)) {
      Ok() => Ok(admin.userName),
      Err(:final failure) => Err(failure),
    };
  }
}
