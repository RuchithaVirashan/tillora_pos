import '../../core/platform/platform_info.dart';

/// Hardware the till talks to. Each has a desktop driver now and a mobile
/// driver later (Bluetooth printer, camera scanner) behind the same interface.
abstract interface class ReceiptPrinter {
  Future<void> printLines(List<String> lines);
  Future<void> openCashDrawer();
}

class HardwareRegistry {
  HardwareRegistry({required this.receiptPrinter});

  final ReceiptPrinter receiptPrinter;

  factory HardwareRegistry.forCurrentPlatform() {
    // TODO: return EscPosUsbPrinter on Windows, BluetoothPrinter on mobile.
    return HardwareRegistry(receiptPrinter: _NoopPrinter(PlatformInfo.isDesktop ? 'desktop' : 'mobile'));
  }
}

class _NoopPrinter implements ReceiptPrinter {
  _NoopPrinter(this.platform);
  final String platform;

  @override
  Future<void> printLines(List<String> lines) async {}

  @override
  Future<void> openCashDrawer() async {}
}
