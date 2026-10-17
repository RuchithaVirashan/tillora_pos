import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../entities/label_product.dart';
import '../repositories/label_repository.dart';

class GetLabelProducts {
  const GetLabelProducts(this._repository);
  final LabelRepository _repository;

  Future<Result<List<LabelProduct>>> call(LabelType type, {required int departmentId}) =>
      _repository.products(type, departmentId: departmentId);
}

class FindLabelProduct {
  const FindLabelProduct(this._repository);
  final LabelRepository _repository;

  Future<Result<LabelProduct>> call(String code, LabelType type) async {
    final c = code.trim();
    if (c.isEmpty) return const Err(ValidationFailure('Enter a product code or PLU code'));
    return switch (await _repository.find(c, type)) {
      Ok(value: final p?) => Ok(p),
      Ok() => Err(ValidationFailure(type == LabelType.weight ? 'No weight product found for $c' : 'No product found for $c')),
      Err(:final failure) => Err(failure),
    };
  }
}

class PrintLabels {
  const PrintLabels(this._repository);
  final LabelRepository _repository;

  static const maxLabels = 500;

  static int labelCount(List<LabelLine> lines) => lines.fold(0, (n, l) => n + l.count);

  Future<Result<void>> call(List<LabelLine> lines, LabelType type, LabelFormat format) async {
    final count = labelCount(lines);
    if (count == 0) return const Err(ValidationFailure('No items to print'));
    if (count > maxLabels) return const Err(ValidationFailure('Print at most $maxLabels labels at a time'));
    return _repository.print(lines, type, format);
  }
}
