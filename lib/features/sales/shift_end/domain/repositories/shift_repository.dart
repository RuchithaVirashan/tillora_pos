import '../../../../../core/errors/result.dart';
import '../../../../../core/reports/shift_summary.dart';

abstract interface class ShiftRepository {
  Future<Result<void>> closeShift(int logId, {required int drawerFloatCents});
  Future<Result<ShiftSummary>> summary(int logId);
}
