import 'package:shared_preferences/shared_preferences.dart';

/// User names that logged in on this device, most recent first.
/// Only names are kept, never passwords.
class RecentLoginsStore {
  RecentLoginsStore(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'recentLoginUserNames';
  static const max = 3;

  /// At most [max]; older lists may hold more, so trim on read too.
  List<String> read() => (_prefs.getStringList(_key) ?? const []).take(max).toList();

  Future<void> remember(String userName) {
    final name = userName.trim();
    final next = [name, ...read().where((n) => n.toLowerCase() != name.toLowerCase())];
    return _prefs.setStringList(_key, next.take(max).toList());
  }

  Future<void> forget(String userName) =>
      _prefs.setStringList(_key, read().where((n) => n.toLowerCase() != userName.toLowerCase()).toList());
}
