import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

import '../core/platform/platform_info.dart';
import '../infrastructure/database/app_database.dart';
import '../infrastructure/hardware/multi_window_customer_display.dart';
import 'app.dart';
import 'customer_display_app.dart';
import 'di/injector.dart';

/// Prepares everything the app needs before the first frame:
/// translations, the local database and the dependency container.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The customer display is a second window running this same entry point.
  if (PlatformInfo.isDesktop) {
    final window = await WindowController.fromCurrentEngine();
    if (CustomerDisplayWindow.isDisplay(window.arguments)) return runCustomerDisplay();
  }

  await EasyLocalization.ensureInitialized();

  final database = AppDatabase();
  await database.open();

  await configureDependencies(database: database);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('fr')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      child: const TilloraApp(),
    ),
  );
}
