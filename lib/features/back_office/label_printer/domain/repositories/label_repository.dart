import '../../../../../core/errors/result.dart';
import '../entities/label_product.dart';

abstract interface class LabelRepository {
  /// Products of the department, A–Z: weighed products for weight labels,
  /// the rest for barcode labels.
  Future<Result<List<LabelProduct>>> products(LabelType type, {required int departmentId});

  /// By barcode, secondary barcode or PLU code.
  Future<Result<LabelProduct?>> find(String code, LabelType type);

  /// Prints each line's label [LabelLine.count] times.
  Future<Result<void>> print(List<LabelLine> lines, LabelType type, LabelFormat format);
}
