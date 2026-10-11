import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/session/user_session.dart';
import '../repositories/user_repository.dart';

class GetUsers {
  const GetUsers(this._repository);
  final UserRepository _repository;

  Future<Result<List<StaffUser>>> call() => _repository.users();
}

/// Adds a user ([existing] null) or updates one.
class SaveUser {
  const SaveUser(this._repository);
  final UserRepository _repository;

  static const minPassword = 4;

  Future<Result<int>> call({
    required StaffUser? existing,
    required String userName,
    required String password,
    required int? roleId,
    required List<StaffUser> all,
    required UserSession session,
  }) async {
    final name = userName.trim();
    if (name.isEmpty) return const Err(ValidationFailure('Enter a user name'));
    if (roleId == null) return const Err(ValidationFailure('Select a role'));
    // Login ignores case and spaces, so names must be unique that way too.
    String key(String n) => n.toLowerCase().replaceAll(' ', '');
    if (all.any((u) => u.id != existing?.id && key(u.userName) == key(name))) {
      return Err(ValidationFailure('$name is already used'));
    }
    if (existing == null) {
      if (password.length < minPassword) return const Err(ValidationFailure('Password must be at least $minPassword characters'));
      return _repository.add(userName: name, password: password, roleId: roleId);
    }
    if (password.isNotEmpty && password.length < minPassword) {
      return const Err(ValidationFailure('Password must be at least $minPassword characters'));
    }
    final roleChanged = roleId != existing.roleId;
    if (roleChanged && existing.id == session.userId) return const Err(ValidationFailure('You cannot change your own role'));
    if (roleChanged && existing.roleId == Roles.admin && all.where((u) => u.roleId == Roles.admin).length == 1) {
      return const Err(ValidationFailure('There must be at least one admin'));
    }
    final result = await _repository.update(
      existing.id,
      userName: name,
      password: password.isEmpty ? null : password,
      roleId: roleId,
      roleChanged: roleChanged,
    );
    return switch (result) {
      Ok() => Ok(existing.id),
      Err(:final failure) => Err(failure),
    };
  }
}

/// Why [user] cannot be deleted, or null when it can.
String? cannotDelete(StaffUser user, {required List<StaffUser> all, required UserSession session}) {
  if (user.id == session.userId) return 'You cannot delete yourself.';
  if (user.onShift) return 'Cannot delete this user. User is on live shift.';
  if (user.roleId == Roles.admin && all.where((u) => u.roleId == Roles.admin).length == 1) {
    return 'Cannot delete the only admin.';
  }
  return null;
}

class DeleteUser {
  const DeleteUser(this._repository);
  final UserRepository _repository;

  Future<Result<void>> call(StaffUser user, {required List<StaffUser> all, required UserSession session}) async {
    if (cannotDelete(user, all: all, session: session) case final reason?) return Err(ValidationFailure(reason));
    return _repository.delete(user.id);
  }
}
