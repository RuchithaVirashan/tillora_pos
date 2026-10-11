import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// One place to ask "what are we running on?".
/// Features never check Platform directly; they ask here or use infrastructure/hardware.
abstract final class PlatformInfo {
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  static bool get isDesktop => isWindows || (!kIsWeb && (Platform.isLinux || Platform.isMacOS));
  static bool get isMobile => isAndroid || isIOS;
}
