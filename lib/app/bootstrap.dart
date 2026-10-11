import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

import '../core/platform/platform_info.dart';
import '../infrastructure/database/app_database.dart';
import 'app.dart';
import 'di/injector.dart';

/// Prepares everything the app needs before the first frame:
/// translations, the local database and the dependency container.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final database = AppDatabase();
  await database.open();

  await configureDependencies(database: database);

  if (PlatformInfo.isDesktop) {
    // Window size, kiosk mode and the customer display window are set up here
    // (window_manager / desktop_multi_window). Mobile skips this.
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('fr')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      child: const TilloraApp(),
    ),
  );
}
