import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../core/reports/report_document.dart';

/// Writes a [ReportDocument] to an .xlsx workbook: one sheet, sections as
/// label / value rows and tables with their header row. Money is a number
/// in rupees so it can be summed.
abstract final class ReportExcel {
  static Uint8List build(ReportDocument doc) {
    final excel = Excel.createExcel();
    const sheetName = 'Report';
    excel.rename(excel.getDefaultSheet() ?? 'Sheet1', sheetName);
    final sheet = excel[sheetName];
    final bold = CellStyle(bold: true);

    final money = CellStyle(numberFormat: NumFormat.standard_4);

    // [moneyAt] marks columns shown as #,##0.00.
    void row(List<CellValue?> cells, {bool header = false, List<bool> moneyAt = const []}) {
      sheet.appendRow(cells);
      final r = sheet.maxRows - 1;
      for (var i = 0; i < cells.length; i++) {
        final style = header ? bold : (i < moneyAt.length && moneyAt[i] ? money : null);
        if (style != null) sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: r)).cellStyle = style;
      }
    }

    CellValue value(ReportCell c) => switch (c) {
      MoneyCell(:final cents) => DoubleCellValue(cents / 100),
      CountCell(:final value) => IntCellValue(value),
      // Dates as dd/MM/yyyy HH:mm text, which reads the same in every locale.
      DateCell() => TextCellValue(c.text),
      TextCell(:final value) => TextCellValue(value),
    };

    row([TextCellValue(doc.title)], header: true);
    for (final s in doc.subtitle) {
      row([TextCellValue(s)]);
    }
    for (final b in doc.blocks) {
      row([]);
      switch (b) {
        case ReportSection(:final title, :final rows):
          row([TextCellValue(title)], header: true);
          for (final (label, cell) in rows) {
            row([TextCellValue(label), value(cell)], moneyAt: [false, cell is MoneyCell]);
          }
        case ReportTable(:final title, :final columns, :final rows):
          if (title.isNotEmpty) row([TextCellValue(title)], header: true);
          row([for (final c in columns) TextCellValue(c)], header: true);
          for (final r in rows) {
            row([for (final c in r) value(c)], moneyAt: [for (final c in r) c is MoneyCell]);
          }
      }
    }
    return Uint8List.fromList(excel.encode() ?? const []);
  }
}
