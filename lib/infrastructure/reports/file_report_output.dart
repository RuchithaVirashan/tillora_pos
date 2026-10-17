import 'package:file_picker/file_picker.dart';

import '../../core/platform/report_output.dart';
import '../../core/reports/report_document.dart';
import '../hardware/hardware_registry.dart';
import 'report_excel.dart';
import 'report_pdf.dart';

class FileReportOutput implements ReportOutput {
  FileReportOutput(this._printer);

  final SystemPrinter _printer;

  @override
  Future<void> printRoll(ReportDocument doc) async => _printer.printPdf(await ReportPdf.roll(doc, paperMm: await _printer.paperWidthMm()), name: doc.title);

  @override
  Future<List<String>> export(ReportDocument doc, Set<ExportFormat> formats) async {
    final saved = <String>[];
    for (final format in ExportFormat.values.where(formats.contains)) {
      final (ext, mime, bytes) = switch (format) {
        ExportFormat.pdf => ('pdf', 'application/pdf', await ReportPdf.a4(doc)),
        ExportFormat.excel => ('xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', ReportExcel.build(doc)),
      };
      final uri = await FilePicker.saveFile(
        dialogTitle: 'Save ${doc.title} as ${ext.toUpperCase()}',
        fileName: '${doc.fileName}.$ext',
        bytes: bytes,
        mimeType: mime,
        type: FileType.custom,
        allowedExtensions: [ext],
      );
      if (uri != null) saved.add(uri.pathSegments.isEmpty ? '${doc.fileName}.$ext' : uri.pathSegments.last);
    }
    return saved;
  }
}
