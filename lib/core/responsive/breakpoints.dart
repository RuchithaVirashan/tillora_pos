import 'package:flutter/widgets.dart';

/// Screen classes the layouts switch on.
/// Phone: handheld POS / mobile app. Tablet: small till. Desktop: Windows till.
enum DeviceClass { phone, tablet, desktop }

abstract final class Breakpoints {
  static const tablet = 700.0;
  static const desktop = 1100.0;

  static DeviceClass of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktop) return DeviceClass.desktop;
    if (width >= tablet) return DeviceClass.tablet;
    return DeviceClass.phone;
  }
}
