import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Passwords are stored as salted SHA-256. A stored plain-text password still
/// verifies and is re-hashed on the next successful login.
abstract final class PasswordHasher {
  static const _prefix = 'sha256:';
  static const _pepper = 'tillora-pos';

  static String hash(String password, {required String userName}) {
    final digest = sha256.convert(utf8.encode('$_pepper:$userName:$password'));
    return '$_prefix$digest';
  }

  static bool verify(String password, {required String userName, required String stored}) {
    if (!isHashed(stored)) return stored == password;
    return hash(password, userName: userName) == stored;
  }

  static bool isHashed(String stored) => stored.startsWith(_prefix);
}
