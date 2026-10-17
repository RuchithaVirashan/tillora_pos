import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../repositories/backup_repository.dart';

class BackupDatabase {
  const BackupDatabase(this._repository);
  final BackupRepository _repository;

  Future<Result<String>> call(String? directory) async {
    if (directory == null || directory.trim().isEmpty) return const Err(ValidationFailure('Please select a directory to backup'));
    return _repository.backup(directory);
  }
}

class RestoreDatabase {
  const RestoreDatabase(this._repository);
  final BackupRepository _repository;

  Future<Result<void>> call(String? file) async {
    if (file == null || file.trim().isEmpty) return const Err(ValidationFailure('Please select a backup file'));
    return _repository.stageRestore(file);
  }
}
