import 'dart:typed_data';

import 'package:pdf/pdf.dart';
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
      if (!ok) throw StateError('${printer.name} did not accept $name');
      return;
    }
    await Printing.layoutPdf(name: name, onLayout: (_) async => bytes);
  }

  Future<Printer?> _pick() async {
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
}

/// Prints receipts as 80 mm PDFs through [SystemPrinter].
class SystemReceiptPrinter implements ReceiptPrinter {
  SystemReceiptPrinter(this._printer);

  final SystemPrinter _printer;

  @override
  Future<void> printReceipt(Receipt receipt) async =>
      _printer.printPdf(await ReceiptPdf.build(receipt, paperMm: await _printer.paperWidthMm()), name: 'Receipt ${receipt.number}');

  /// Opening the drawer needs raw ESC/POS output to the receipt printer,
  /// which the system print service cannot send; not wired yet.
  @override
  Future<void> openCashDrawer() async {}
}
