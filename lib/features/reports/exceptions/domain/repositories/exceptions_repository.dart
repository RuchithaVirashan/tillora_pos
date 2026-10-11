import '../../../../../core/errors/result.dart';
import '../entities/exception_record.dart';

abstract interface class ExceptionsRepository {
  /// Newest first. [to] is exclusive.
  Future<Result<List<ExceptionRecord>>> records(ExceptionType type, {required DateTime from, required DateTime to, int? logId});
}
