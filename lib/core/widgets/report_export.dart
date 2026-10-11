import 'package:material_ui/material_ui.dart';

import '../platform/report_output.dart';
import '../reports/report_document.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'feedback.dart';
import 'pos_button.dart';
import 'pos_dialog.dart';

/// Print Report: asks for PDF, Excel, both, or a copy on the till printer,
/// then saves or prints [doc] and says what happened.
Future<void> printOrExportReport(BuildContext context, ReportDocument doc, ReportOutput output) async {
  final choice = await showDialog<_Choice>(
    context: context,
    barrierColor: AppColors.scrim.withValues(alpha: 0.82),
    builder: (context) => const _ExportDialog(),
  );
  if (choice == null || !context.mounted) return;
  try {
    if (choice == _Choice.till) {
      await output.printRoll(doc);
      if (context.mounted) showToast(context, '${doc.title} sent to the printer');
      return;
    }
    final saved = await output.export(doc, choice.formats);
    if (!context.mounted) return;
    showToast(context, saved.isEmpty ? 'Export cancelled' : 'Saved ${saved.join(' and ')}');
  } catch (e) {
    if (context.mounted) showToast(context, 'Could not ${choice == _Choice.till ? 'print' : 'export'} the report: $e', error: true);
  }
}

/// Prints [doc] on the till printer straight away (Shift End).
Future<void> printReport(BuildContext context, ReportDocument doc, ReportOutput output) async {
  try {
    await output.printRoll(doc);
    if (context.mounted) showToast(context, '${doc.title} sent to the printer');
  } catch (e) {
    if (context.mounted) showToast(context, 'Could not print the report: $e', error: true);
  }
}

enum _Choice {
  pdf({ExportFormat.pdf}),
  excel({ExportFormat.excel}),
  both({ExportFormat.pdf, ExportFormat.excel}),
  till({});

  const _Choice(this.formats);
  final Set<ExportFormat> formats;
}

class _ExportDialog extends StatelessWidget {
  const _ExportDialog();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget option(_Choice choice, String label, IconData icon) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PosButton(
        label: label,
        icon: icon,
        height: 56,
        fontSize: 15,
        style: PosButtonStyle.secondary,
        onPressed: () => Navigator.pop(context, choice),
      ),
    );
    return PosDialog(
      title: 'Print Report',
      icon: Icons.print_outlined,
      iconColor: c.primary,
      iconFill: c.selection,
      width: 460,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Select Export Format', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.inkSecondary)),
          const SizedBox(height: 12),
          option(_Choice.pdf, 'PDF', Icons.picture_as_pdf_outlined),
          option(_Choice.excel, 'Excel', Icons.table_chart_outlined),
          option(_Choice.both, 'Both PDF & Excel', Icons.file_copy_outlined),
          option(_Choice.till, 'Print on till printer', Icons.receipt_long_outlined),
          const SizedBox(height: 4),
          PosButton(label: 'Cancel', height: 52, style: PosButtonStyle.function, onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}
