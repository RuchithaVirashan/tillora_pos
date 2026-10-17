import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as mobile;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/platform/platform_info.dart';
import 'seed/default_data.dart';
import 'tables/schema.dart';

/// Opens the single local SQLite database.
/// Windows uses sqflite_common_ffi; Android and iOS use sqflite.
/// Schema version is 38 so existing databases open without migration.
/// One connection is opened at startup and shared through `app/di`.
class AppDatabase {
  static const fileName = 'tillora.db';
  static const schemaVersion = 38;

  late final Database db;

  Future<void> open() async {
    final DatabaseFactory factory;
    if (PlatformInfo.isDesktop) {
      sqfliteFfiInit();
      factory = databaseFactoryFfi;
    } else {
      factory = mobile.databaseFactory;
    }
    final dir = await getApplicationSupportDirectory();
    await _applyPendingRestore(dir.path);
    db = await factory.openDatabase(
      p.join(dir.path, fileName),
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onUpgrade: (db, from, to) async {
          // Add one migration file per version under infrastructure/database/migrations/.
        },
        // Runs on every open, not just onCreate: a file already at version 38
        // skips onCreate, so missing tables, indexes and first-run data are
        // added here. Every statement is IF NOT EXISTS, so this is cheap.
        onOpen: (db) => db.transaction((txn) async {
          final batch = txn.batch();
          for (final sql in [...Schema.dropped, ...Schema.tables, ...Schema.indexes]) {
            batch.execute(sql);
          }
          await batch.commit(noResult: true);
          await addMissingColumns(txn);
          final users = await txn.rawQuery('SELECT COUNT(*) AS n FROM userDetails');
          if (users.first['n'] == 0) await DefaultData.seed(txn);
        }),
      ),
    );
  }

  /// Adds [Schema.addedColumns] missing from an older database.
  static Future<void> addMissingColumns(DatabaseExecutor db) async {
    for (final (table, column, type) in Schema.addedColumns) {
      final columns = await db.rawQuery('PRAGMA table_info($table)');
      if (!columns.any((c) => c['name'] == column)) await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  /// A restored backup waiting for the next start.
  static const pendingRestoreName = '$fileName.restore';

  /// The database as it was before the last restore.
  static const beforeRestoreName = '$fileName.before-restore';

  static Future<String> directory() async => (await getApplicationSupportDirectory()).path;

  /// Swaps in a backup staged by Backup & Restore. The database cannot be
  /// replaced while open, so this runs before opening it.
  static Future<void> _applyPendingRestore(String dir) async {
    final pending = File(p.join(dir, pendingRestoreName));
    if (!await pending.exists()) return;
    final current = File(p.join(dir, fileName));
    if (await current.exists()) await current.copy(p.join(dir, beforeRestoreName));
    await pending.copy(current.path);
    await pending.delete();
  }

  /// Why [path] cannot be restored, or null when it is a Tillora database.
  static Future<String?> checkBackup(String path) async {
    final DatabaseFactory factory = PlatformInfo.isDesktop ? databaseFactoryFfi : mobile.databaseFactory;
    if (PlatformInfo.isDesktop) sqfliteFfiInit();
    Database? backup;
    try {
      backup = await factory.openDatabase(path, options: OpenDatabaseOptions(readOnly: true, singleInstance: false));
      final tables = {
        for (final r in await backup.rawQuery("SELECT name FROM sqlite_master WHERE type = 'table'")) r['name'] as String,
      };
      final missing = ['products', 'Transactions', 'userDetails'].where((t) => !tables.contains(t)).toList();
      if (missing.isNotEmpty) return 'This is not a Tillora backup (no ${missing.join(', ')} table)';
      final check = await backup.rawQuery('PRAGMA quick_check');
      if (check.first.values.first != 'ok') return 'The backup file is damaged';
      return null;
    } catch (e) {
      return '$e'.contains('not a database') ? 'That file is not a database' : 'Could not open the backup file';
    } finally {
      await backup?.close();
    }
  }
}
