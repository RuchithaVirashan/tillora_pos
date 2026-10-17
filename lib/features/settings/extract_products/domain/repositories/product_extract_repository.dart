import 'dart:typed_data';

import '../../../../../core/errors/result.dart';

/// The products table of a database file as CSV, with a header row.
typedef ProductCsv = ({int products, Uint8List bytes});

abstract interface class ProductExtractRepository {
  /// Reads the `products` table of the SQLite file at [path].
  Future<Result<ProductCsv>> extract(String path);
}
