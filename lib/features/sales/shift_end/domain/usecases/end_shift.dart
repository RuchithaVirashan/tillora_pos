import '../../../../../core/errors/result.dart';
import '../../../../../core/session/user_session.dart';
import '../entities/shift_summary.dart';
import '../repositories/shift_repository.dart';

/// Closes the shift with the float left in the drawer and returns the
/// shift end report.
class EndShift {
  const EndShift(this._repository);

  final ShiftRepository _repository;

  Future<Result<ShiftSummary>> call(UserSession session, {required int drawerFloatCents}) async {
    final logId = session.logId ?? 0;
    final closed = await _repository.closeShift(logId, drawerFloatCents: drawerFloatCents);
    if (closed case Err(:final failure)) return Err(failure);
    return _repository.summary(logId, userName: session.userName);
  }
}
