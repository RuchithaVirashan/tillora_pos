import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/db_date.dart';
import '../../domain/repositories/staff_activity_repository.dart';

class StaffActivityRepositoryImpl implements StaffActivityRepository {
  StaffActivityRepositoryImpl(this._db);

  final Database _db;

  /// One query: each user joined to their latest shift.
  @override
  Future<Result<List<StaffStatus>>> staff() async {
    try {
      final rows = await _db.rawQuery(
        'SELECT u.id, u.userName, u.roleId, l.ShiftStarted, l.Status FROM userDetails u '
        'LEFT JOIN logDetails l ON l.LogId = (SELECT MAX(LogId) FROM logDetails WHERE Userid = CAST(u.id AS TEXT)) '
        "ORDER BY (l.Status = '1') DESC, l.ShiftStarted DESC, u.userName",
      );
      return Ok([
        for (final r in rows)
          (
            userId: r['id'] as int,
            userName: r['userName'] as String,
            roleId: r['roleId'] as int,
            shiftStarted: DbDate.tryParse(r['ShiftStarted'] as String?),
            onShift: r['Status'] == '1',
          ),
      ]);
    } catch (e) {
      return Err(DatabaseFailure('Could not load staff activity: $e'));
    }
  }
}
