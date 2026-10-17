import 'dart:typed_data';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../entities/data_import.dart';
import '../repositories/data_import_repository.dart';

/// Fills a table from a CSV or Excel file, matching columns by heading.
class ImportData {
  const ImportData(this._repository);
  final DataImportRepository _repository;

  static const extensions = ['csv', 'xlsx'];

  static String _normal(String heading) => heading.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');

  /// Header row → `column index → database column` for [table].
  static Map<int, String> mapHeader(ImportTable table, List<String> header) {
    final byHeading = {for (final (i, h) in header.indexed) _normal(h): i};
    return {
      for (final MapEntry(key: column, value: names) in table.columns.entries) ?names.map((n) => byHeading[n]).nonNulls.firstOrNull: column,
    };
  }

  Future<Result<ImportSummary>> call(ImportTable? table, Uint8List? bytes, String extension) async {
    if (table == null) return const Err(ValidationFailure('Please select table'));
    if (bytes == null) return const Err(ValidationFailure('No file selected. Please select an Excel or CSV file'));
    if (!extensions.contains(extension.toLowerCase())) return const Err(ValidationFailure('Choose a .csv or .xlsx file'));

    final List<List<String>> rows;
    switch (await _repository.readTable(bytes, extension.toLowerCase())) {
      case Ok(:final value):
        rows = value;
      case Err(:final failure):
        return Err(failure);
    }
    if (rows.length < 2) return const Err(ValidationFailure('The file has no rows to import'));

    final columns = mapHeader(table, rows.first);
    final missing = table.required.where((c) => !columns.containsValue(c)).toList();
    if (missing.isNotEmpty) return Err(ValidationFailure('Missing column: ${missing.join(', ')}'));

    final records = [
      for (final row in rows.skip(1))
        if (row.any((cell) => cell.trim().isNotEmpty))
          {for (final MapEntry(key: i, value: column) in columns.entries) if (i < row.length) column: row[i].trim()},
    ];
    if (records.isEmpty) return const Err(ValidationFailure('The file has no rows to import'));
    return _repository.insert(table, records);
  }
}
