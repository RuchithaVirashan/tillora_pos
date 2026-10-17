import '../../../../../core/errors/result.dart';
import '../entities/sale_line.dart';

abstract interface class SalesManagerRepository {
  /// Closed shifts that started in `[from, to)`, newest first.
  Future<Result<List<ShiftOption>>> shifts(DateTime from, DateTime to);

  /// Sold lines (not discounts or refunds) of closed shifts, dated in
  /// `[from, to)`, optionally of one shift.
  Future<Result<List<SaleLine>>> lines(DateTime from, DateTime to, {int? logId});

  /// Takes the lines off their sales: lowers each sale's total (the
  /// difference is counted as change given back), returns the items to
  /// stock and removes sales left with nothing sold.
  Future<Result<void>> remove(List<SaleLine> lines);

  /// Lowers one line's quantity, adjusting its sale the same way.
  Future<Result<void>> alter(SaleLine line, int quantity);
}
