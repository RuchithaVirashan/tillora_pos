import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import 'access_rights.dart';

/// Seeded roles (`userDetails.roleId`).
abstract final class Roles {
  static const admin = 1;
  static const manager = 2;
  static const cashier = 3;

  static String name(int roleId) => switch (roleId) {
    admin => 'Admin',
    manager => 'Manager',
    cashier => 'Cashier',
    _ => 'Role $roleId',
  };
}

/// The logged-in user and, for Sales, their open shift (`logDetails.LogId`).
class UserSession extends Equatable {
  const UserSession({
    required this.userId,
    required this.userName,
    required this.roleId,
    required this.access,
    required this.loggedInAt,
    this.logId,
  });

  final int userId;
  final String userName;
  final int roleId;
  final AccessRights access;
  final DateTime loggedInAt;

  /// Open shift id. Only set after logging in to Sales.
  final int? logId;

  bool get isAdmin => roleId == Roles.admin;

  UserSession withShift(int logId, DateTime startedAt) => UserSession(
    userId: userId,
    userName: userName,
    roleId: roleId,
    access: access,
    loggedInAt: startedAt,
    logId: logId,
  );

  @override
  List<Object?> get props => [userId, roleId, logId, loggedInAt];
}

/// Holds the current session for the whole app. Registered once in `app/di`;
/// the router redirects to login when it is empty.
class SessionHolder extends ValueNotifier<UserSession?> {
  SessionHolder() : super(null);

  UserSession get current {
    final session = value;
    if (session == null) throw StateError('No user is logged in');
    return session;
  }

  void signIn(UserSession session) => value = session;
  void signOut() => value = null;
}
