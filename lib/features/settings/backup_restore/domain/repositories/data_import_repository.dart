import 'dart:typed_data';

import '../../../../../core/errors/result.dart';
import '../entities/data_import.dart';

abstract interface class DataImportRepository {
  /// The first sheet of an `.xlsx` file, or a `.csv` file, as rows of text;
  /// the first row is the header.
  Future<Result<List<List<String>>>> readTable(Uint8List bytes, String extension);

  /// Inserts [rows] (database column → value) into [table] in one
  /// transaction, skipping rows whose key already exists.
  Future<Result<ImportSummary>> insert(ImportTable table, List<Map<String, String>> rows);
}
