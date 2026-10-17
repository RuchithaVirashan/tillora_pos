import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../infrastructure/database/app_database.dart';
import '../../domain/repositories/backup_repository.dart';

class BackupRepositoryImpl implements BackupRepository {
  BackupRepositoryImpl(this._db);

  final Database _db;

  @override
  Future<Result<String>> backup(String directory) async {
    try {
      final name = 'tillora-backup-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}.db';
      final path = p.join(directory, name);
      // VACUUM INTO copies a consistent snapshot while the till stays open.
      await _db.execute("VACUUM INTO '${path.replaceAll("'", "''")}'");
      return Ok(path);
    } catch (e) {
      return Err(DatabaseFailure('Backup failed: $e'));
    }
  }

  @override
  Future<Result<void>> stageRestore(String file) async {
    if (await AppDatabase.checkBackup(file) case final problem?) return Err(ValidationFailure(problem));
    try {
      await File(file).copy(p.join(await AppDatabase.directory(), AppDatabase.pendingRestoreName));
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseFailure('Could not stage the restore: $e'));
    }
  }
}
