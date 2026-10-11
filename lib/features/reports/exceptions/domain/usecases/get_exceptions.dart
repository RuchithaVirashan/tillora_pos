import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../entities/exception_record.dart';
import '../repositories/exceptions_repository.dart';

/// Exceptions of one type between two whole days, optionally for one shift.
class GetExceptions {
  const GetExceptions(this._repository);
  final ExceptionsRepository _repository;

  Future<Result<List<ExceptionRecord>>> call(ExceptionType type, {required DateTime from, required DateTime to, int? logId}) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day).add(const Duration(days: 1));
    if (!end.isAfter(start)) return Future.value(const Err(ValidationFailure('End date is before start date')));
    return _repository.records(type, from: start, to: end, logId: logId);
  }
}
