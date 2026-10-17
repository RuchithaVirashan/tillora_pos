import '../../../../../core/errors/result.dart';
import '../entities/back_office_report.dart';

abstract interface class BackOfficeReportRepository {
  /// Best sellers first.
  Future<Result<List<SaleRow>>> sales(ReportFilter filter);

  /// Every barcode product matching the filter, A–Z, with what sold in
  /// the period.
  Future<Result<List<MovementRow>>> movement(ReportFilter filter);

  /// Newest first. [ReportFilter.query] matches the barcode.
  Future<Result<List<AdjustmentRow>>> adjustments(ReportFilter filter);
}
