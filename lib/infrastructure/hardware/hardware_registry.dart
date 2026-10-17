import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../core/receipts/receipt.dart';
import 'receipt_pdf.dart';
import 'windows_raw_printer.dart';

/// Hardware the till talks to. Each has a desktop driver now and a mobile
/// driver later (Bluetooth printer, camera scanner) behind the same interface.
abstract interface class ReceiptPrinter {
  Future<void> printReceipt(Receipt receipt);
  Future<void> openCashDrawer();
}

class HardwareRegistry {
  HardwareRegistry({required this.receiptPrinter});

  final ReceiptPrinter receiptPrinter;
}

/// Sends PDFs to the till printer through the operating system's print
/// service: the configured printer when installed, else the default
/// printer, else the print dialog.
class SystemPrinter {
  SystemPrinter(this._printerName, [this._paperWidth]);

  final Future<String?> Function() _printerName;
  final Future<String?> Function()? _paperWidth;

  /// Roll paper sizes the till printer can be set to, in mm.
  static const paperWidths = [80, 72, 66, 64, 58];

  /// The roll width set in System Configuration; 80 mm when unset.
  Future<double> paperWidthMm() async {
    final mm = int.tryParse((await _paperWidth?.call()) ?? '');
    return (paperWidths.contains(mm) ? mm! : 80).toDouble();
  }

  /// A continuous roll [mm] wide with 4 mm side margins.
  static PdfPageFormat roll(double mm) =>
      PdfPageFormat(mm * PdfPageFormat.mm, double.infinity, marginLeft: 4 * PdfPageFormat.mm, marginRight: 4 * PdfPageFormat.mm, marginTop: 2 * PdfPageFormat.mm, marginBottom: 2 * PdfPageFormat.mm);

  Future<void> printPdf(Uint8List bytes, {required String name}) async {
    final printer = await _pick();
    if (printer != null) {
      final ok = await Printing.directPrintPdf(printer: printer, name: name, onLayout: (_) async => bytes);
      if (!ok) throw PrinterException('${printer.name} did not accept $name');
      return;
    }
    await Printing.layoutPdf(name: name, onLayout: (_) async => bytes);
  }

  Future<Printer?> _pick() async {
    final info = await Printing.info();
    if (!info.canListPrinters || !info.directPrint) return null;
    final printers = await Printing.listPrinters();
    return await _configuredFrom(printers) ?? printers.where((p) => p.isAvailable && p.isDefault).firstOrNull;
  }

  /// The printer chosen in System Configuration, when it is installed.
  /// Never falls back to the default printer.
  Future<String?> configuredPrinterName() async {
    if ((await _printerName())?.trim().isEmpty ?? true) return null;
    final info = await Printing.info();
    if (!info.canListPrinters) return null;
    return (await _configuredFrom(await Printing.listPrinters()))?.name;
  }

  Future<Printer?> _configuredFrom(List<Printer> printers) async {
    final wanted = (await _printerName())?.trim().toLowerCase();
    if (wanted == null || wanted.isEmpty) return null;
    return printers.where((p) => p.isAvailable && p.name.toLowerCase() == wanted).firstOrNull;
  }
}

/// Prints receipts as 80 mm PDFs through [SystemPrinter].
class SystemReceiptPrinter implements ReceiptPrinter {
  SystemReceiptPrinter(this._printer);

  final SystemPrinter _printer;

  @override
  Future<void> printReceipt(Receipt receipt) async =>
      _printer.printPdf(await ReceiptPdf.build(receipt, paperMm: await _printer.paperWidthMm()), name: 'Receipt ${receipt.number}');

  /// ESC p: pulse drawer pin 2, then pin 5, for 50 ms on / 500 ms off.
  /// Drawers are wired to one pin or the other, so both are sent.
  static final drawerKick = Uint8List.fromList([0x1B, 0x70, 0x00, 0x19, 0xFA, 0x1B, 0x70, 0x01, 0x19, 0xFA]);

  /// The drawer plugs into the receipt printer, which opens it when sent
  /// [drawerKick] as raw ESC/POS. Only the receipt printer chosen in System
  /// Configuration gets it: on any other printer the bytes would print.
  @override
  Future<void> openCashDrawer() async {
    if (!WindowsRawPrinter.isSupported) return;
    final printer = await _printer.configuredPrinterName();
    if (printer == null) throw PrinterException('Choose the receipt printer in Settings > System Configuration');
    WindowsRawPrinter.send(printer, drawerKick, job: 'Open cash drawer');
  }
}
