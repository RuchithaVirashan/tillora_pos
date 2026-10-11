import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/session/access_rights.dart';
import '../../../../../core/session/user_session.dart';
import '../repositories/role_access_repository.dart';

class GetAccessUsers {
  const GetAccessUsers(this._repository);
  final RoleAccessRepository _repository;

  Future<Result<List<AccessUser>>> call() => _repository.users();
}

class GetUserAccess {
  const GetUserAccess(this._repository);
  final RoleAccessRepository _repository;

  Future<Result<AccessRights>> call(AccessUser user) => _repository.accessFor(user);
}

class SaveUserAccess {
  const SaveUserAccess(this._repository);
  final RoleAccessRepository _repository;

  /// Admins keep Back Office, Role Access and Settings, so nobody can lock
  /// everyone out of changing access again.
  Future<Result<void>> call(AccessUser user, AccessRights access, {required UserSession session}) async {
    if (user.roleId == Roles.admin && (!access.can(AccessRights.backOffice) || !access.can('roleAccessManagerAccess'))) {
      return const Err(ValidationFailure('Admins must keep Backoffice Login and Role Access Manager access'));
    }
    if (user.id == session.userId && !access.can('roleAccessManagerAccess')) {
      return const Err(ValidationFailure('You cannot remove your own Role Access Manager access'));
    }
    for (final flag in const [AccessRights.noSaleCount, AccessRights.voidSaleCount, AccessRights.voidLineCount]) {
      if (access.limit(flag) < 0) return const Err(ValidationFailure('Counts cannot be negative'));
    }
    return _repository.save(user, access);
  }
}
