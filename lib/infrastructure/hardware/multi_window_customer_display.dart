import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/platform/customer_display.dart';

/// Window arguments and channel shared by the till and the display window.
abstract final class CustomerDisplayWindow {
  static const type = 'customerDisplay';
  static final arguments = jsonEncode({'type': type});
  static const channel = WindowMethodChannel('tillora/customer_display');

  /// Sent by the display when it starts; answered with the latest frame.
  static const ready = 'ready';

  /// Sent by the till with a frame as JSON.
  static const frame = 'frame';

  static bool isDisplay(String windowArguments) {
    if (windowArguments.isEmpty) return false;
    try {
      return (jsonDecode(windowArguments) as Map)['type'] == type;
    } on FormatException {
      return false;
    }
  }
}

/// Customer display in its own desktop window (desktop_multi_window).
class MultiWindowCustomerDisplay implements CustomerDisplay {
  WindowController? _window;
  DisplayFrame? _last;
  DisplayStyle _style = const DisplayStyle();
  bool _open = false;
  bool _listening = false;

  @override
  bool get isSupported => true;

  @override
  bool get isOpen => _open;

  @override
  Future<void> open() async {
    if (!_listening) {
      _listening = true;
      await CustomerDisplayWindow.channel.setMethodCallHandler((call) async {
        if (call.method == CustomerDisplayWindow.ready) return _last?.toJson();
        throw MissingPluginException(call.method);
      });
    }
    _window ??= await _existing() ??
        await WindowController.create(WindowConfiguration(arguments: CustomerDisplayWindow.arguments, hiddenAtLaunch: false));
    await _window!.show();
    _open = true;
    final last = _last;
    if (last != null) await show(last);
  }

  @override
  Future<void> close() async {
    _open = false;
    await _window?.hide();
  }

  @override
  Future<void> applyStyle(DisplayStyle style) async {
    _style = style;
    final last = _last;
    if (last != null) await show(last);
  }

  @override
  Future<void> show(DisplayFrame frame) async {
    _last = frame.withStyle(_style);
    if (!_open) return;
    try {
      await CustomerDisplayWindow.channel.invokeMethod(CustomerDisplayWindow.frame, _last!.toJson());
    } on WindowChannelException catch (e) {
      // The display window is still starting; it asks for the frame itself.
      debugPrint('Customer display not ready: ${e.code}');
    }
  }

  Future<WindowController?> _existing() async {
    for (final w in await WindowController.getAll()) {
      if (CustomerDisplayWindow.isDisplay(w.arguments)) return w;
    }
    return null;
  }
}

/// For platforms without a second window (Android, iOS).
class NoCustomerDisplay implements CustomerDisplay {
  @override
  bool get isSupported => false;

  @override
  bool get isOpen => false;

  @override
  Future<void> open() async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> show(DisplayFrame frame) async {}

  @override
  Future<void> applyStyle(DisplayStyle style) async {}
}
