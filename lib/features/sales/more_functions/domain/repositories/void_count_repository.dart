import '../../../../../core/errors/result.dart';

abstract interface class VoidCountRepository {
  /// Starts the shift's void line, void sale and no sale counts again. The
  /// earlier records stay in the log.
  Future<Result<void>> reset({required int logId, required String approvedBy});
}
