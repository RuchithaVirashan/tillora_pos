import 'package:intl/intl.dart';

import '../../../../../core/reports/report_document.dart';
import 'expired_items_repository.dart';

/// The expired items report as a printable / exportable document.
/// [before] null means everything expired by today.
ReportDocument expiredItemsDocument({required List<ExpiredProduct> items, DateTime? before}) {
  final day = DateFormat('dd/MM/yyyy');
  final cutoff = before ?? DateTime.now();
  return ReportDocument(
    title: 'Expired Items Report',
    fileName: 'expired-items-${DateFormat('yyyyMMdd').format(cutoff)}',
    subtitle: [
      before == null ? 'All items expired by ${day.format(cutoff)}' : 'Expired on or before ${day.format(cutoff)}',
      '${items.length} products · ${items.fold(0, (n, i) => n + i.stock)} in stock',
    ],
    blocks: [
      ReportTable(
        'PRODUCTS',
        columns: const ['Barcode', 'Description', 'Department', 'Expiry', 'Stock'],
        rows: [
          for (final i in items)
            [TextCell(i.barcode), TextCell(i.description), TextCell(i.departmentName), DateCell(i.expiryDate, withTime: false), CountCell(i.stock)],
        ],
      ),
    ],
  );
}
