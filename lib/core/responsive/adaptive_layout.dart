import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

/// Picks a layout for the current screen size.
///
/// Every screen keeps one bloc and one set of widgets; only the arrangement
/// differs. Put each arrangement in the feature's `presentation/layouts/`
/// folder, for example `sales_desktop_layout.dart` and `sales_mobile_layout.dart`.
class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({super.key, required this.desktop, required this.mobile, this.tablet});

  final WidgetBuilder desktop;
  final WidgetBuilder mobile;

  /// Falls back to [desktop] when not given.
  final WidgetBuilder? tablet;

  @override
  Widget build(BuildContext context) {
    switch (Breakpoints.of(context)) {
      case DeviceClass.desktop:
        return desktop(context);
      case DeviceClass.tablet:
        return (tablet ?? desktop)(context);
      case DeviceClass.phone:
        return mobile(context);
    }
  }
}
