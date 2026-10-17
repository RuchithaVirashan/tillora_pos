import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/reports/report_document.dart';
import '../hardware/hardware_registry.dart';

/// Lays out a [ReportDocument] as an A4 file or on an 80 mm roll.
abstract final class ReportPdf {
  /// A4 for exported files: sections as label / value lists, tables with a
  /// header row, and page numbers.
  static Future<Uint8List> a4(ReportDocument doc) {
    final pdf = pw.Document(title: doc.title, author: 'Tillora POS');
    const navy = PdfColor.fromInt(0xFF0D2547);
    const line = PdfColor.fromInt(0xFFE3E8EF);
    const muted = PdfColor.fromInt(0xFF667085);
    final printed = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pw.Widget section(ReportSection s) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(s.title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: muted, letterSpacing: 0.8)),
        pw.SizedBox(height: 4),
        for (final (label, cell) in s.rows)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: line, width: 0.5))),
            child: pw.Row(
              children: [
                pw.Expanded(child: pw.Text(label, style: const pw.TextStyle(fontSize: 10))),
                pw.Text(cell.text, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
        pw.SizedBox(height: 14),
      ],
    );

    pw.Widget table(ReportTable t) {
      final numeric = [for (var i = 0; i < t.columns.length; i++) t.rows.isNotEmpty && t.rows.first[i].numeric];
      final alignments = {for (var i = 0; i < numeric.length; i++) i: numeric[i] ? pw.Alignment.centerRight : pw.Alignment.centerLeft};
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          if (t.title.isNotEmpty) ...[
            pw.Text(t.title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: muted, letterSpacing: 0.8)),
            pw.SizedBox(height: 4),
          ],
          if (t.rows.isEmpty)
            pw.Text('No records', style: const pw.TextStyle(fontSize: 10, color: muted))
          else
            pw.TableHelper.fromTextArray(
              headers: t.columns,
              data: [for (final r in t.rows) [for (final c in r) c.text]],
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: navy),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignments: alignments,
              headerAlignments: alignments,
              oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF7F9FB)),
              border: null,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            ),
          pw.SizedBox(height: 14),
        ],
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(doc.title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: navy)),
            for (final s in doc.subtitle) pw.Text(s, style: const pw.TextStyle(fontSize: 10, color: muted)),
            pw.Divider(color: line),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Tillora POS · printed $printed', style: const pw.TextStyle(fontSize: 8, color: muted)),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: muted)),
          ],
        ),
        build: (_) => [
          for (final b in doc.blocks)
            switch (b) {
              ReportSection() => section(b),
              ReportTable() => table(b),
            },
        ],
      ),
    );
    return pdf.save();
  }

  /// 80 mm roll for the till printer. Tables print one record per block.
  static Future<Uint8List> roll(ReportDocument doc, {double paperMm = 80}) {
    final pdf = pw.Document(title: doc.title, author: 'Tillora POS');
    const base = pw.TextStyle(fontSize: 8.5);
    final bold = base.copyWith(fontWeight: pw.FontWeight.bold);

    pw.Widget pair(String left, String right, {pw.TextStyle? style}) => pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [pw.Expanded(child: pw.Text(left, style: style ?? base)), pw.SizedBox(width: 6), pw.Text(right, style: style ?? base)],
    );
    pw.Widget rule() => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Divider(height: 1, thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: SystemPrinter.roll(paperMm),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(doc.title.toUpperCase(), textAlign: pw.TextAlign.center, style: bold.copyWith(fontSize: 11)),
            for (final s in doc.subtitle) pw.Text(s, textAlign: pw.TextAlign.center, style: base),
            for (final b in doc.blocks) ...[
              rule(),
              pw.Text(b.title, style: bold),
              pw.SizedBox(height: 2),
              ...switch (b) {
                ReportSection(:final rows) => [for (final (label, cell) in rows) pair(label, cell.text)],
                ReportTable(:final columns, :final rows) => [
                  for (final r in rows) ...[
                    for (var i = 0; i < columns.length; i++) pair(columns[i], r[i].text),
                    pw.SizedBox(height: 3),
                  ],
                ],
              },
            ],
            rule(),
            pw.Text('Printed ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', textAlign: pw.TextAlign.center, style: base),
          ],
        ),
      ),
    );
    return pdf.save();
  }
}
