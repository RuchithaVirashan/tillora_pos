import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../core/platform/customer_display.dart';
import '../core/theme/app_theme.dart';
import '../features/sales/customer_display/presentation/screens/customer_display_screen.dart';
import '../infrastructure/hardware/multi_window_customer_display.dart';

/// Entry point for the customer display window. It runs in its own engine,
/// with no database: everything it shows comes from the till over the
/// window channel.
Future<void> runCustomerDisplay() async {
  final frames = ValueNotifier<DisplayFrame?>(null);
  DisplayFrame? decode(Object? json) => json is Map ? DisplayFrame.fromJson(json.cast<String, Object?>()) : null;

  await CustomerDisplayWindow.channel.setMethodCallHandler((call) async {
    if (call.method != CustomerDisplayWindow.frame) throw MissingPluginException(call.method);
    frames.value = decode(call.arguments) ?? frames.value;
  });

  runApp(MaterialApp(
    title: 'Customer Display',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: CustomerDisplayScreen(frames: frames),
  ));

  try {
    frames.value = decode(await CustomerDisplayWindow.channel.invokeMethod(CustomerDisplayWindow.ready));
  } on Exception catch (e) {
    debugPrint('Customer display could not reach the till yet: $e');
  }
}
