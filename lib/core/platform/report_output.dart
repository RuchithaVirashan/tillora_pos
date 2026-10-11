import '../reports/report_document.dart';

/// Prints reports on the till printer and saves them as files.
/// Implemented in `infrastructure/reports`.
abstract interface class ReportOutput {
  /// 80 mm copy on the till printer.
  Future<void> printRoll(ReportDocument doc);

  /// Asks where to save each format and writes it. Returns the names of the
  /// files saved; empty if every save was cancelled.
  Future<List<String>> export(ReportDocument doc, Set<ExportFormat> formats);
}
