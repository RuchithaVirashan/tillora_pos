import 'package:intl/intl.dart';

/// LKR formatting used on screens, receipts and reports: `Rs 1,250.00`.
abstract final class Money {
  static final _format = NumberFormat('#,##0.00', 'en_US');

  static String lkr(num amount) {
    final text = 'Rs ${_format.format(amount.abs())}';
    return amount < 0 ? '−$text' : text;
  }

  /// Amounts are stored as integer cents to avoid floating point drift.
  static int toCents(num rupees) => (rupees * 100).round();
  static double fromCents(int cents) => cents / 100;
}
