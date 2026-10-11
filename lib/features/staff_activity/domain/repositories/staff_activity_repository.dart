import '../../../../core/errors/result.dart';

/// A user and their latest shift. [shiftStarted] is null if they never
/// opened one.
typedef StaffStatus = ({int userId, String userName, int roleId, DateTime? shiftStarted, bool onShift});

abstract interface class StaffActivityRepository {
  /// Users on shift first, then by latest shift start.
  Future<Result<List<StaffStatus>>> staff();
}
