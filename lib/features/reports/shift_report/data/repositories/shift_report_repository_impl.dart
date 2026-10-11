import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/reports/shift_summary.dart';
import '../../../../../core/utils/db_date.dart';
import '../../../../../infrastructure/database/dao/shift_report_dao.dart';
import '../../domain/repositories/shift_report_repository.dart';

class ShiftReportRepositoryImpl implements ShiftReportRepository {
  ShiftReportRepositoryImpl(this._reports);

  final ShiftReportDao _reports;

  @override
  Future<Result<List<ShiftOption>>> shifts({bool openOnly = false, DateTime? from, DateTime? to, int? userId}) => _guard(() async {
    final rows = await _reports.shifts(openOnly: openOnly, from: from, to: to, userId: userId);
    return [
      for (final r in rows)
        (
          logId: r['LogId'] as int,
          userName: (r['userName'] as String?) ?? '',
          startedAt: DbDate.tryParse(r['ShiftStarted'] as String?) ?? DateTime.now(),
          endedAt: DbDate.tryParse(r['ShiftEnd'] as String?),
          open: r['Status'] == '1',
        ),
    ];
  });

  @override
  Future<Result<List<UserOption>>> users() =>
      _guard(() async => [for (final r in await _reports.users()) (id: r['id'] as int, name: r['userName'] as String)]);

  @override
  Future<Result<ShiftSummary>> report(int logId) => _guard(() => _reports.summary(logId));

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }
}
