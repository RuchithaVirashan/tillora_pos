import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as mobile;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/platform/platform_info.dart';

/// Opens the single local SQLite database.
/// Windows uses sqflite_common_ffi; Android and iOS use sqflite.
/// Schema version continues from the old app (38) so existing data can be reused.
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
        onCreate: (db, version) async {
          // Port CREATE TABLE statements from old lib/db/helper/table.dart
          // into infrastructure/database/tables/, one file per table, and run them here.
        },
        onUpgrade: (db, from, to) async {
          // Add one migration file per version under infrastructure/database/migrations/.
        },
      ),
    );
  }
}
