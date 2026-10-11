import '../../../../../core/errors/result.dart';
import '../../../../../core/session/access_rights.dart';

typedef AccessUser = ({int id, String userName, int roleId});

abstract interface class RoleAccessRepository {
  Future<Result<List<AccessUser>>> users();

  /// The user's own access, else their role's defaults.
  Future<Result<AccessRights>> accessFor(AccessUser user);

  /// Saves [access] as the user's own access row.
  Future<Result<void>> save(AccessUser user, AccessRights access);
}
