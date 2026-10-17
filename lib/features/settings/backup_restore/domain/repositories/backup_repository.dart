import '../../../../../core/errors/result.dart';

abstract interface class BackupRepository {
  /// Writes a consistent copy of the database into [directory]. Returns
  /// the file's path.
  Future<Result<String>> backup(String directory);

  /// Checks [file] is a Tillora database and stages it; it replaces the
  /// current database the next time Tillora starts.
  Future<Result<void>> stageRestore(String file);
}
