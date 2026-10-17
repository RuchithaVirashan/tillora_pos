import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/config/terminal_info.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../domain/entities/company_details.dart';
import '../../domain/repositories/company_repository.dart';

/// `companyDetails` holds a single row.
class CompanyRepositoryImpl implements CompanyRepository {
  CompanyRepositoryImpl(this._db, this._terminal);

  final Database _db;
  final TerminalInfoHolder _terminal;

  @override
  Future<Result<CompanyDetails>> details() => _guard(() async {
    final rows = await _db.query('companyDetails', orderBy: 'id', limit: 1);
    if (rows.isEmpty) return CompanyDetails.empty;
    final r = rows.first;
    String v(String key) => '${r[key] ?? ''}';
    return CompanyDetails(name: v('Name'), address1: v('Address1'), address2: v('Address2'), phone: v('Phone'), phone2: v('Phone2'), vatNo: v('Vatno'));
  });

  @override
  Future<Result<void>> save(CompanyDetails d) => _guard(() async {
    final values = {
      'Name': d.name,
      'Address1': d.address1,
      'Address2': d.address2,
      'Phone': d.phone,
      'Phone2': d.phone2,
      'Vatno': d.vatNo,
      'cloudSync': 0,
    };
    final rows = await _db.query('companyDetails', columns: ['id'], orderBy: 'id', limit: 1);
    if (rows.isEmpty) {
      await _db.insert('companyDetails', values);
    } else {
      await _db.update('companyDetails', values, where: 'id = ?', whereArgs: [rows.first['id']]);
    }
    _terminal.value = _terminal.value.copyWith(companyName: d.name);
  });

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }
}
