import 'dart:io';

import '../../core/platform/platform_info.dart';
import '../../core/platform/system_tools.dart';

class OsSystemTools implements SystemTools {
  @override
  Future<bool> openCalculator() async {
    if (!PlatformInfo.isWindows) return false;
    try {
      await Process.start('calc.exe', const [], mode: ProcessStartMode.detached);
      return true;
    } catch (_) {
      return false;
    }
  }
}
