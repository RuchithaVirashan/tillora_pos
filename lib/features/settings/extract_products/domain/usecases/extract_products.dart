import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../repositories/product_extract_repository.dart';

class ExtractProducts {
  const ExtractProducts(this._repository);
  final ProductExtractRepository _repository;

  Future<Result<ProductCsv>> call(String? path) async {
    if (path == null || path.isEmpty) return const Err(ValidationFailure('Click here to select SQLite database file'));
    return switch (await _repository.extract(path)) {
      Ok(value: (products: 0, bytes: _)) => const Err(ValidationFailure('That database has no products')),
      final other => other,
    };
  }
}
