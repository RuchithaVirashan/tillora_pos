import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/receipts/receipt.dart';

/// Lays out a [Receipt] on an 80 mm roll.
abstract final class ReceiptPdf {
  static final _money = NumberFormat('#,##0.00', 'en_US');
  static final _date = DateFormat('dd/MM/yyyy HH:mm');

  /// Plain ASCII so the built-in PDF fonts can print it.
  static String rs(int cents) => '${cents < 0 ? '-' : ''}Rs ${_money.format(cents.abs() / 100)}';

  static Future<Uint8List> build(Receipt r) {
    final doc = pw.Document(title: 'Receipt ${r.number}', author: 'Tillora POS');
    const base = pw.TextStyle(fontSize: 8.5);
    final bold = base.copyWith(fontWeight: pw.FontWeight.bold);
    const small = pw.TextStyle(fontSize: 7.5);

    pw.Widget pair(String left, String right, {pw.TextStyle? style}) => pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: pw.Text(left, style: style ?? base)),
        pw.SizedBox(width: 6),
        pw.Text(right, style: style ?? base),
      ],
    );
    pw.Widget rule() => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Divider(height: 1, thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80.copyWith(marginLeft: 4 * PdfPageFormat.mm, marginRight: 4 * PdfPageFormat.mm),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            for (final (i, line) in r.header.indexed)
              pw.Text(line, textAlign: pw.TextAlign.center, style: i == 0 ? bold.copyWith(fontSize: 11) : base),
            if (r.reprint || r.isRefund) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                [if (r.isRefund) 'REFUND', if (r.reprint) 'COPY'].join(' - '),
                textAlign: pw.TextAlign.center,
                style: bold.copyWith(fontSize: 10),
              ),
            ],
            rule(),
            pair('Receipt ${r.number}', _date.format(r.at)),
            pair('Cashier: ${r.cashier}', r.terminal),
            rule(),
            for (final l in r.lines) ...[
              pw.Text(l.name, style: l.isDiscount ? base : bold),
              if (l.isDiscount)
                pair('', rs(l.amountCents))
              else
                pair('  ${l.quantity} x ${rs(l.priceCents)}', rs(l.amountCents)),
              pw.SizedBox(height: 2),
            ],
            rule(),
            pair(r.isRefund ? 'REFUND TOTAL' : 'TOTAL', rs(r.totalCents), style: bold.copyWith(fontSize: 11)),
            pw.SizedBox(height: 3),
            for (final (method, cents) in r.payments) pair(method, rs(cents)),
            if (r.changeCents != 0) pair('Change', rs(r.changeCents)),
            pw.SizedBox(height: 3),
            pair('Items', '${r.itemCount}', style: small),
            rule(),
            for (final line in r.footer) pw.Text(line, textAlign: pw.TextAlign.center, style: base),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.code128(),
                data: r.transactionId.toString().padLeft(6, '0'),
                width: 120,
                height: 28,
                textStyle: small,
              ),
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }
}
