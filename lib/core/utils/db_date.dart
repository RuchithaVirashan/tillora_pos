import 'package:intl/intl.dart';

/// Dates are stored as `yyyy-MM-dd HH:mm:ss` text.
abstract final class DbDate {
  static final _format = DateFormat('yyyy-MM-dd HH:mm:ss');

  static String format(DateTime value) => _format.format(value);
  static String now() => format(DateTime.now());
  static DateTime? tryParse(String? value) =>
      (value == null || value.isEmpty) ? null : DateTime.tryParse(value);

  /// `[start of day, start of next day)` as stored strings, for range queries.
  static (String, String) dayRange(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    return (format(start), format(start.add(const Duration(days: 1))));
  }
}
