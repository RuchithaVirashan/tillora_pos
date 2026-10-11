import 'app/bootstrap.dart';

/// Single entry point for Windows, Android and iOS.
/// Platform differences are handled in [bootstrap] and in `core/platform`.
Future<void> main() => bootstrap();
