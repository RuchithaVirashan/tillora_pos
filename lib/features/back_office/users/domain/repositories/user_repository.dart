import '../../../../../core/errors/result.dart';

typedef StaffUser = ({int id, String userName, int roleId, bool onShift});

abstract interface class UserRepository {
  /// A–Z, each with whether they have an open shift.
  Future<Result<List<StaffUser>>> users();

  /// Adds the user with their role's default access. Returns the new id.
  Future<Result<int>> add({required String userName, required String password, required int roleId});

  /// [password] null keeps the current one. A role change resets the
  /// user's access to that role's defaults.
  Future<Result<void>> update(int id, {required String userName, String? password, required int roleId, required bool roleChanged});

  Future<Result<void>> delete(int id);
}
