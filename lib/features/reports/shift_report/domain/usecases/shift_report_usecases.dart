import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/reports/shift_summary.dart';
import '../repositories/shift_report_repository.dart';

class GetLiveShifts {
  const GetLiveShifts(this._repository);
  final ShiftReportRepository _repository;

  Future<Result<List<ShiftOption>>> call() => _repository.shifts(openOnly: true);
}

/// Shifts started between [from] and [to] (both whole days), optionally for one user.
class FindShifts {
  const FindShifts(this._repository);
  final ShiftReportRepository _repository;

  Future<Result<List<ShiftOption>>> call({required DateTime from, required DateTime to, int? userId}) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day).add(const Duration(days: 1));
    if (!end.isAfter(start)) return Future.value(const Err(ValidationFailure('End date is before start date')));
    return _repository.shifts(from: start, to: end, userId: userId);
  }
}

class GetReportUsers {
  const GetReportUsers(this._repository);
  final ShiftReportRepository _repository;

  Future<Result<List<UserOption>>> call() => _repository.users();
}

class GetShiftReport {
  const GetShiftReport(this._repository);
  final ShiftReportRepository _repository;

  Future<Result<ShiftSummary>> call(int? logId) {
    if (logId == null) return Future.value(const Err(ValidationFailure('Please select a shift')));
    return _repository.report(logId);
  }
}
