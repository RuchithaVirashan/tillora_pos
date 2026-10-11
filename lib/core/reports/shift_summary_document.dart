import 'package:intl/intl.dart';

import 'report_document.dart';
import 'shift_summary.dart';

/// The shift report sections, shared by the screen, printing and export.
List<ReportSection> shiftSummarySections(ShiftSummary s) {
  String hour(int h) => '${h.toString().padLeft(2, '0')}:00';
  return [
    ReportSection('CASH FLOW', [
      ('Drawer float', MoneyCell(s.drawerFloatCents)),
      for (final e in s.salesByMethod.entries) ('${e.key} sales', MoneyCell(e.value)),
      ('Refunds', MoneyCell(s.refundsCents)),
      ('Cash lifts', MoneyCell(s.cashLiftsCents)),
      ('Expected in drawer', MoneyCell(s.expectedInDrawerCents)),
    ]),
    ReportSection(
      'DEPARTMENT',
      s.salesByDepartment.isEmpty
          ? const [('No sales', TextCell(''))]
          : [for (final e in s.salesByDepartment.entries) (e.key, MoneyCell(e.value))],
    ),
    ReportSection('ACTIVITY', [
      ('Transactions', CountCell(s.transactionCount)),
      ('Total takings', MoneyCell(s.totalCents)),
      ('No sales', CountCell(s.noSaleCount)),
      ('Void lines', CountCell(s.voidLineCount)),
      ('Void sales', CountCell(s.voidSaleCount)),
    ]),
    ReportSection(
      'HOURLY SALE',
      s.salesByHour.isEmpty
          ? const [('No sales', TextCell(''))]
          : [for (final e in s.salesByHour.entries) ('${hour(e.key)} - ${hour(e.key + 1)}', MoneyCell(e.value))],
    ),
  ];
}

ReportDocument shiftSummaryDocument(ShiftSummary s, {required String terminal, int? shiftId}) {
  final time = DateFormat('dd/MM/yyyy HH:mm');
  return ReportDocument(
    title: 'Shift Report',
    fileName: 'shift-report${shiftId == null ? '' : '-${shiftId.toString().padLeft(6, '0')}'}-${DateFormat('yyyyMMdd-HHmm').format(s.startedAt)}',
    subtitle: [
      if (s.userName.isNotEmpty) 'Cashier: ${s.userName}',
      'Terminal: $terminal',
      'From ${time.format(s.startedAt)} to ${time.format(s.endedAt)}',
    ],
    blocks: shiftSummarySections(s),
  );
}
