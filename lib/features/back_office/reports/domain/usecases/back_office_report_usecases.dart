import 'package:intl/intl.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/reports/report_document.dart';
import '../entities/back_office_report.dart';
import '../repositories/back_office_report_repository.dart';

Result<ReportFilter>? _check(ReportFilter f) =>
    f.to.isBefore(f.from) ? const Err(ValidationFailure('End date must be on or after the start date')) : null;

class GetSaleReport {
  const GetSaleReport(this._repository);
  final BackOfficeReportRepository _repository;

  Future<Result<List<SaleRow>>> call(ReportFilter filter) async => switch (_check(filter)) {
    Err(:final failure) => Err(failure),
    _ => await _repository.sales(filter),
  };
}

class GetStockMovement {
  const GetStockMovement(this._repository);
  final BackOfficeReportRepository _repository;

  Future<Result<List<MovementRow>>> call(ReportFilter filter) async => switch (_check(filter)) {
    Err(:final failure) => Err(failure),
    _ => await _repository.movement(filter),
  };
}

class GetStockAdjustments {
  const GetStockAdjustments(this._repository);
  final BackOfficeReportRepository _repository;

  Future<Result<List<AdjustmentRow>>> call(ReportFilter filter) async => switch (_check(filter)) {
    Err(:final failure) => Err(failure),
    _ => await _repository.adjustments(filter),
  };
}

/// Sale totals: what sold, what it cost and the profit on it.
({int sales, int cost, int profit}) saleTotals(List<SaleRow> rows) {
  final sales = rows.fold(0, (s, r) => s + r.totalCents);
  final cost = rows.fold(0, (s, r) => s + r.costCents);
  return (sales: sales, cost: cost, profit: sales - cost);
}

/// A Back Office report as a printable / exportable document.
/// [category] is the chosen category's name, null for all.
ReportDocument backOfficeReportDocument(
  BackOfficeReport report,
  ReportFilter filter, {
  String? category,
  List<SaleRow> sales = const [],
  List<MovementRow> movement = const [],
  List<AdjustmentRow> adjustments = const [],
}) {
  final day = DateFormat('dd/MM/yyyy');
  final file = DateFormat('yyyyMMdd');
  final subtitle = [
    '${day.format(filter.from)} – ${day.format(filter.to)}',
    if (category != null) 'Category: $category',
    if (filter.query.trim().isNotEmpty) 'Search: ${filter.query.trim()}',
  ];
  final blocks = <ReportBlock>[
    switch (report) {
      BackOfficeReport.sale => () {
        final t = saleTotals(sales);
        return ReportSection('SUMMARY', [('Total Sales', MoneyCell(t.sales)), ('Total Cost', MoneyCell(t.cost)), ('Total Profit', MoneyCell(t.profit))]);
      }(),
      BackOfficeReport.movement => ReportSection('SUMMARY', [
        ('Products', CountCell(movement.length)),
        ('Units Sold', CountCell(movement.fold(0, (s, r) => s + r.sold))),
        ('Units In Stock', CountCell(movement.fold(0, (s, r) => s + r.stock))),
      ]),
      BackOfficeReport.adjustment => ReportSection('SUMMARY', [
        ('Adjustments', CountCell(adjustments.length)),
        ('Units Added', CountCell(adjustments.fold(0, (s, r) => s + (r.quantity > 0 ? r.quantity : 0)))),
        ('Units Removed', CountCell(adjustments.fold(0, (s, r) => s + (r.quantity < 0 ? -r.quantity : 0)))),
      ]),
    },
    switch (report) {
      BackOfficeReport.sale => ReportTable(
        'PRODUCTS',
        columns: const ['Barcode', 'Description', 'Category', 'Qty Sold', 'Unit Price', 'Total'],
        rows: [
          for (final r in sales)
            [TextCell(r.barcode), TextCell(r.description), TextCell(r.category), CountCell(r.quantity), MoneyCell(r.unitPriceCents), MoneyCell(r.totalCents)],
        ],
      ),
      BackOfficeReport.movement => ReportTable(
        'PRODUCTS',
        columns: const ['Barcode', 'Description', 'Category', 'Current Stock', 'Stock Sold', 'Price'],
        rows: [
          for (final r in movement)
            [TextCell(r.barcode), TextCell(r.description), TextCell(r.category), CountCell(r.stock), CountCell(r.sold), MoneyCell(r.priceCents)],
        ],
      ),
      BackOfficeReport.adjustment => ReportTable(
        'ADJUSTMENTS',
        columns: const ['Barcode', 'Description', 'Type', 'Before', 'After', 'Qty', 'Adjusted At', 'Category'],
        rows: [
          for (final r in adjustments)
            [
              TextCell(r.barcode),
              TextCell(r.description),
              TextCell(r.type),
              CountCell(r.before),
              CountCell(r.after),
              CountCell(r.quantity),
              DateCell(r.at),
              TextCell(r.category),
            ],
        ],
      ),
    },
  ];
  return ReportDocument(
    title: report.title,
    fileName: '${report.name}-report-${file.format(filter.from)}-${file.format(filter.to)}',
    subtitle: subtitle,
    blocks: blocks,
  );
}
