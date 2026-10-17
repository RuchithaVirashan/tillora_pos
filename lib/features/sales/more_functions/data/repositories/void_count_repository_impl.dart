import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../infrastructure/database/dao/pos_records_dao.dart';
import '../../domain/repositories/void_count_repository.dart';

class VoidCountRepositoryImpl implements VoidCountRepository {
  VoidCountRepositoryImpl(this._records);

  final PosRecordsDao _records;

  @override
  Future<Result<void>> reset({required int logId, required String approvedBy}) async {
    try {
      await _records.resetCounts(logId: logId, approvedBy: approvedBy);
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseFailure('Could not reset the counts: $e'));
    }
  }
}
