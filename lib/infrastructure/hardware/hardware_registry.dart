import 'package:printing/printing.dart';

import '../../core/receipts/receipt.dart';
import 'receipt_pdf.dart';

/// Hardware the till talks to. Each has a desktop driver now and a mobile
/// driver later (Bluetooth printer, camera scanner) behind the same interface.
abstract interface class ReceiptPrinter {
  Future<void> printReceipt(Receipt receipt);
  Future<void> openCashDrawer();
}

class HardwareRegistry {
  HardwareRegistry({required this.receiptPrinter});

  final ReceiptPrinter receiptPrinter;

  /// [printerName] reads the configured receipt printer (sysConfig `posprinter`).
  factory HardwareRegistry.forCurrentPlatform({Future<String?> Function()? printerName}) =>
      HardwareRegistry(receiptPrinter: SystemReceiptPrinter(printerName ?? () async => null));
}

/// Prints through the operating system's print service (Windows printers,
/// Android/iOS print dialog) as an 80 mm PDF.
///
/// Uses the configured printer when it is installed, else the default
/// printer, else asks with the print dialog.
class SystemReceiptPrinter implements ReceiptPrinter {
  SystemReceiptPrinter(this._printerName);

  final Future<String?> Function() _printerName;

  @override
  Future<void> printReceipt(Receipt receipt) async {
    final bytes = await ReceiptPdf.build(receipt);
    final name = 'Receipt ${receipt.number}';
    final printer = await _pickPrinter();
    if (printer != null) {
      final ok = await Printing.directPrintPdf(printer: printer, name: name, onLayout: (_) async => bytes);
      if (!ok) throw StateError('${printer.name} did not accept the receipt');
      return;
    }
    await Printing.layoutPdf(name: name, onLayout: (_) async => bytes);
  }

  Future<Printer?> _pickPrinter() async {
    final info = await Printing.info();
    if (!info.canListPrinters || !info.directPrint) return null;
    final printers = await Printing.listPrinters();
    final wanted = (await _printerName())?.trim().toLowerCase();
    if (wanted != null && wanted.isNotEmpty) {
      for (final p in printers) {
        if (p.isAvailable && p.name.toLowerCase() == wanted) return p;
      }
    }
    for (final p in printers) {
      if (p.isAvailable && p.isDefault) return p;
    }
    return null;
  }

  /// Opening the drawer needs raw ESC/POS output to the receipt printer,
  /// which the system print service cannot send; not wired yet.
  @override
  Future<void> openCashDrawer() async {}
}
