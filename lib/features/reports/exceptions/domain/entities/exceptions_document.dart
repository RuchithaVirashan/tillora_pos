import 'package:intl/intl.dart';

import '../../../../../core/reports/report_document.dart';
import 'exception_record.dart';

/// The exception report as a printable / exportable document.
ReportDocument exceptionsDocument({
  required ExceptionType type,
  required DateTime from,
  required DateTime to,
  required List<ExceptionRecord> records,
  String? shift,
}) {
  final day = DateFormat('dd/MM/yyyy');
  String receipt(int id) => '#${id.toString().padLeft(6, '0')}';
  return ReportDocument(
    title: 'Exception Report · ${type.label}',
    fileName: 'exceptions-${type.label.toLowerCase().replaceAll(' ', '-')}-${DateFormat('yyyyMMdd').format(from)}-${DateFormat('yyyyMMdd').format(to)}',
    subtitle: [
      '${day.format(from)} to ${day.format(to)}',
      'Shift: ${shift ?? 'All shifts'}',
      '${records.length} ${records.length == 1 ? 'record' : 'records'} · total ${MoneyCell(records.fold(0, (s, r) => s + r.amountCents)).text}',
    ],
    blocks: [
      ReportTable(
        'RECORDS',
        columns: const ['Receipt', 'Date', 'User', 'Reason', 'Amount'],
        rows: [
          for (final r in records) [TextCell(receipt(r.id)), DateCell(r.at), TextCell(r.userName), TextCell(r.reason), MoneyCell(r.amountCents)],
        ],
      ),
      ReportTable(
        'ITEMS',
        columns: const ['Receipt', 'Item', 'Qty', 'Price', 'Amount'],
        rows: [
          for (final r in records)
            for (final i in r.items)
              [TextCell(receipt(r.id)), TextCell(i.name), CountCell(i.quantity), MoneyCell(i.priceCents), MoneyCell(i.amountCents)],
        ],
      ),
    ],
  );
}
