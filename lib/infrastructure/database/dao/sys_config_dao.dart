import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Key/value settings in `sysConfig` and the company row.
class SysConfigDao {
  SysConfigDao(this._db);

  final Database _db;

  Future<String?> get(String parameter) async {
    final rows = await _db.query('sysConfig', columns: ['Value'], where: 'Parameter = ?', whereArgs: [parameter], limit: 1);
    return rows.isEmpty ? null : rows.first['Value'] as String?;
  }

  /// Reads several parameters in one query.
  Future<Map<String, String>> getMany(List<String> parameters) async {
    final rows = await _db.query(
      'sysConfig',
      columns: ['Parameter', 'Value'],
      where: 'Parameter IN (${List.filled(parameters.length, '?').join(',')})',
      whereArgs: parameters,
    );
    return {for (final r in rows) r['Parameter'] as String: '${r['Value']}'};
  }

  Future<void> set(String parameter, String value) async {
    final updated = await _db.update('sysConfig', {'Value': value, 'cloudSync': 0}, where: 'Parameter = ?', whereArgs: [parameter]);
    if (updated == 0) await _db.insert('sysConfig', {'Parameter': parameter, 'Value': value});
  }

  Future<String> companyName() async {
    final rows = await _db.query('companyDetails', columns: ['Name'], limit: 1);
    return rows.isEmpty ? '' : rows.first['Name'] as String;
  }
}
