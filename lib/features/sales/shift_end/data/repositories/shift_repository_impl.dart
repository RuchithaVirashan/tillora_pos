import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/reports/shift_summary.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../infrastructure/database/dao/shift_dao.dart';
import '../../../../../infrastructure/database/dao/shift_report_dao.dart';
import '../../domain/repositories/shift_repository.dart';

class ShiftRepositoryImpl implements ShiftRepository {
  ShiftRepositoryImpl(this._shifts, this._reports);

  final ShiftDao _shifts;
  final ShiftReportDao _reports;

  @override
  Future<Result<void>> closeShift(int logId, {required int drawerFloatCents}) async {
    try {
      await _shifts.closeShift(logId, drawerFloat: Money.fromCents(drawerFloatCents));
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseFailure('Could not close the shift: $e'));
    }
  }

  @override
  Future<Result<ShiftSummary>> summary(int logId) async {
    try {
      return Ok(await _reports.summary(logId));
    } catch (e) {
      return Err(DatabaseFailure('Could not build the shift report: $e'));
    }
  }
}
