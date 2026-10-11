import 'package:get_it/get_it.dart';

import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/hardware/hardware_registry.dart';

final getIt = GetIt.instance;

/// Registers shared services. Each feature registers its own repositories
/// and use cases here as it is ported from the old app.
Future<void> configureDependencies({required AppDatabase database}) async {
  getIt
    ..registerSingleton<AppDatabase>(database)
    ..registerLazySingleton<HardwareRegistry>(HardwareRegistry.forCurrentPlatform);
}
