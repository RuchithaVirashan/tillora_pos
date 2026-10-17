/// Which Back Office report, with its access flag.
enum BackOfficeReport {
  sale('Sale', 'Sale Report', 'saleReportAccess'),
  movement('Stock Movement', 'Stock Movement Report', 'stockMovementReportAccess'),
  adjustment('Stock Adjustment', 'Stock Adjustment Report', 'stockAdjustmentReportAccess');

  const BackOfficeReport(this.tab, this.title, this.accessFlag);
  final String tab;
  final String title;
  final String accessFlag;
}

/// What to report on. The period runs from the start of [from] to the end
/// of [to]; [departmentId] null means every category.
typedef ReportFilter = ({DateTime from, DateTime to, int? departmentId, String query});

/// Sales of one product over the period, net of refunds. [costCents] is 0
/// when the product has no cost price.
typedef SaleRow = ({String barcode, String description, String category, int quantity, int unitPriceCents, int totalCents, int costCents});

typedef MovementRow = ({int productId, String barcode, String description, String category, int stock, int sold, int priceCents});

typedef AdjustmentRow = ({
  int id,
  String barcode,
  String description,
  String type,
  int before,
  int after,
  int quantity,
  DateTime at,
  String category,
});
