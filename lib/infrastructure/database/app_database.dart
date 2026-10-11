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
          for (final sql in [...Schema.tables, ...Schema.indexes]) {
            batch.execute(sql);
          }
          await batch.commit(noResult: true);
          final users = await txn.rawQuery('SELECT COUNT(*) AS n FROM userDetails');
          if (users.first['n'] == 0) await DefaultData.seed(txn);
        }),
      ),
    );
  }
}
