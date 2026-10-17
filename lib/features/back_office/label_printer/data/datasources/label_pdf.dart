import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/label_product.dart';

/// Renders shelf and weight labels as a PDF.
abstract final class LabelPdf {
  static final _money = NumberFormat('#,##0.00', 'en_US');

  /// A4 sheet: 3 columns × 7 rows of 70 × 38 mm.
  static const _sheetColumns = 3, _sheetRows = 7;
  static const _sheetLabel = (width: 70.0, height: 38.0);

  /// Brother QL 62 mm continuous roll, cut at 29 mm.
  static const _rollLabel = (width: 62.0, height: 29.0);

  /// [paperMm] is the till roll width, for [LabelFormat.receipt].
  static Future<Uint8List> build(List<LabelLine> lines, LabelType type, LabelFormat format, {double paperMm = 80}) {
    final labels = [for (final l in lines) for (var i = 0; i < l.count; i++) l.product];
    final doc = pw.Document(title: '${type.label}s');
    switch (format) {
      case LabelFormat.roll:
        final page = PdfPageFormat(_rollLabel.width * PdfPageFormat.mm, _rollLabel.height * PdfPageFormat.mm);
        for (final p in labels) {
          doc.addPage(pw.Page(pageFormat: page, margin: pw.EdgeInsets.zero, build: (_) => _label(p, type, _rollLabel)));
        }
      case LabelFormat.receipt:
        final width = paperMm - 8;
        doc.addPage(
          // A roll page has no fixed height, so all labels go on one page.
          pw.Page(
            pageFormat: PdfPageFormat(paperMm * PdfPageFormat.mm, double.infinity, marginLeft: 4 * PdfPageFormat.mm, marginRight: 4 * PdfPageFormat.mm),
            build: (_) => pw.Column(
              children: [
                for (final p in labels)
                  pw.Container(
                    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5, style: pw.BorderStyle.dashed))),
                    child: _label(p, type, (width: width, height: _rollLabel.height)),
                  ),
              ],
            ),
          ),
        );
      case LabelFormat.sheet:
        const perPage = _sheetColumns * _sheetRows;
        // Centre the grid on the page.
        final top = (297 - _sheetRows * _sheetLabel.height) / 2 * PdfPageFormat.mm;
        for (var start = 0; start < labels.length; start += perPage) {
          final page = labels.sublist(start, (start + perPage).clamp(0, labels.length));
          doc.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: pw.EdgeInsets.only(top: top),
              build: (_) => pw.Wrap(children: [for (final p in page) _label(p, type, _sheetLabel)]),
            ),
          );
        }
    }
    return doc.save();
  }

  static pw.Widget _label(LabelProduct p, LabelType type, ({double width, double height}) size) {
    final mm = PdfPageFormat.mm;
    final small = size.height < 30;
    final weight = type == LabelType.weight;
    final code = weight && (p.pluCode?.isNotEmpty ?? false) ? p.pluCode! : p.barcode;
    final barcode = pw.Barcode.ean13().isValid(code) ? pw.Barcode.ean13() : pw.Barcode.code128();
    final was = p.wasPriceCents;
    return pw.Container(
      width: size.width * mm,
      height: size.height * mm,
      padding: pw.EdgeInsets.symmetric(horizontal: 3 * mm, vertical: (small ? 1.5 : 3) * mm),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            p.description,
            maxLines: 2,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(fontSize: small ? 8 : 9.5, fontWeight: pw.FontWeight.bold),
          ),
          pw.Spacer(),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.BarcodeWidget(
                barcode: barcode,
                data: code,
                width: (small ? 26 : 30) * mm,
                height: (small ? 10 : 12) * mm,
                textStyle: const pw.TextStyle(fontSize: 6),
              ),
              pw.Spacer(),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  if (was != null && !weight)
                    pw.Text('Was Rs ${_money.format(was / 100)}', style: const pw.TextStyle(fontSize: 7, decoration: pw.TextDecoration.lineThrough)),
                  pw.Text('Rs ${_money.format(p.priceCents / 100)}', style: pw.TextStyle(fontSize: small ? 13 : 15, fontWeight: pw.FontWeight.bold)),
                  if (weight) pw.Text('per kg', style: const pw.TextStyle(fontSize: 7)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
