import 'package:intl/intl.dart';

/// A value in a report. Typed so exports keep numbers as numbers.
sealed class ReportCell {
  const ReportCell();

  /// How the value reads on screen and in PDFs.
  String get text;

  /// Money and counts line up on the right.
  bool get numeric => false;
}

final class TextCell extends ReportCell {
  const TextCell(this.value);
  final String value;

  @override
  String get text => value;
}

final class MoneyCell extends ReportCell {
  const MoneyCell(this.cents);
  final int cents;

  static final _format = NumberFormat('#,##0.00', 'en_US');

  @override
  String get text => '${cents < 0 ? '-' : ''}Rs ${_format.format(cents.abs() / 100)}';

  @override
  bool get numeric => true;
}

final class CountCell extends ReportCell {
  const CountCell(this.value);
  final int value;

  @override
  String get text => '$value';

  @override
  bool get numeric => true;
}

final class DateCell extends ReportCell {
  const DateCell(this.value, {this.withTime = true});
  final DateTime value;
  final bool withTime;

  @override
  String get text => DateFormat(withTime ? 'dd/MM/yyyy HH:mm' : 'dd/MM/yyyy').format(value);
}

sealed class ReportBlock {
  const ReportBlock(this.title);
  final String title;
}

/// Label / value rows, like the cards on the shift report.
final class ReportSection extends ReportBlock {
  const ReportSection(super.title, this.rows);
  final List<(String, ReportCell)> rows;
}

/// A table with a header row.
final class ReportTable extends ReportBlock {
  const ReportTable(super.title, {required this.columns, required this.rows});
  final List<String> columns;
  final List<List<ReportCell>> rows;
}

/// A report ready to print or export.
class ReportDocument {
  const ReportDocument({required this.title, required this.fileName, this.subtitle = const [], required this.blocks});

  final String title;

  /// Who, when and where, one line each.
  final List<String> subtitle;
  final List<ReportBlock> blocks;

  /// Without extension, e.g. `shift-report-000012`.
  final String fileName;
}

/// Output formats offered by Print Report.
enum ExportFormat { pdf, excel }
