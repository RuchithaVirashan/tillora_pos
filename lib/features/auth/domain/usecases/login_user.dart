import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/session/user_session.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/login_module.dart';
import '../repositories/auth_repository.dart';

class LoginParams {
  const LoginParams({required this.userName, required this.password, required this.module});

  final String userName;
  final String password;
  final LoginModule module;
}

/// Logs in to one area of the app. For Sales this also opens (or resumes)
/// the user's shift.
class LoginUser implements UseCase<UserSession, LoginParams> {
  const LoginUser(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<UserSession>> call(LoginParams params) async {
    final userName = params.userName.trim();
    if (userName.isEmpty || params.password.isEmpty) {
      return const Err(ValidationFailure('Please enter your user name and password'));
    }

    final auth = await _repository.authenticate(userName: userName, password: params.password);
    if (auth case Err()) return auth;
    final session = (auth as Ok<UserSession>).value;

    final flag = params.module.accessFlag;
    final allowed = flag == null ? session.isAdmin : session.access.can(flag);
    if (!allowed) {
      return Err(PermissionFailure(
        flag == null ? 'Only admin can access settings' : 'You do not have ${params.module.title} access',
      ));
    }

    final result = params.module == LoginModule.sales ? await _repository.openShift(session) : Ok(session);
    if (result.isSuccess) await _repository.rememberUserName(session.userName);
    return result;
  }
}

/// Recently used user names on this device, for quick picks on login.
class GetRecentUserNames {
  const GetRecentUserNames(this._repository);
  final AuthRepository _repository;

  Future<List<String>> call() => _repository.recentUserNames();
}

class ForgetUserName {
  const ForgetUserName(this._repository);
  final AuthRepository _repository;

  Future<void> call(String userName) => _repository.forgetUserName(userName);
}
