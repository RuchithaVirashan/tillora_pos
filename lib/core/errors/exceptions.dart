/// Thrown by data sources (database, hardware, files).
/// Repositories catch these and return a [Failure] instead.
class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.cause});
}

class HardwareException extends AppException {
  const HardwareException(super.message, {super.cause});
}

class FileException extends AppException {
  const FileException(super.message, {super.cause});
}
