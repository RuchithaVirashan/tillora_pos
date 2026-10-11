import '../../../../../core/errors/result.dart';
import '../../../../../core/reports/shift_summary.dart';

typedef ShiftOption = ({int logId, String userName, DateTime startedAt, DateTime? endedAt, bool open});
typedef UserOption = ({int id, String name});

abstract interface class ShiftReportRepository {
  Future<Result<List<ShiftOption>>> shifts({bool openOnly = false, DateTime? from, DateTime? to, int? userId});
  Future<Result<List<UserOption>>> users();
  Future<Result<ShiftSummary>> report(int logId);
}
