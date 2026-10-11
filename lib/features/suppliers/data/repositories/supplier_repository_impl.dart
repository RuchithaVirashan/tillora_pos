import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/repositories/supplier_repository.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  SupplierRepositoryImpl(this._db);

  final Database _db;

  @override
  Future<Result<List<Supplier>>> suppliers() => _guard(() async {
    final rows = await _db.query('supplierDetails', orderBy: 'name COLLATE NOCASE');
    return [
      for (final r in rows)
        Supplier(
          id: r['id'] as int,
          name: r['name'] as String,
          address: _decodeAddress(r['address'] as String?),
          phone: (r['phoneNumber'] as String?) ?? '',
          email: (r['email'] as String?) ?? '',
        ),
    ];
  });

  @override
  Future<Result<int>> add(Supplier supplier) => _guard(() => _db.insert('supplierDetails', _toRow(supplier)));

  @override
  Future<Result<void>> update(Supplier supplier) => _guard(
    () => _db.update('supplierDetails', {..._toRow(supplier), 'cloudSync': 0}, where: 'id = ?', whereArgs: [supplier.id]),
  );

  @override
  Future<Result<void>> delete(int id) => _guard(() => _db.delete('supplierDetails', where: 'id = ?', whereArgs: [id]));

  static Map<String, Object?> _toRow(Supplier s) => {
    'name': s.name,
    'address': jsonEncode({
      'addressNo': s.address.number,
      'street': s.address.street,
      'district': s.address.district,
      'country': s.address.country,
    }),
    'email': s.email,
    'phoneNumber': s.phone,
  };

  /// Addresses are JSON (`addressNo`, `street`, `district`, `country`);
  /// anything else is kept as a single street line.
  static SupplierAddress _decodeAddress(String? raw) {
    if (raw == null || raw.isEmpty) return const SupplierAddress();
    try {
      final m = jsonDecode(raw);
      if (m is Map) {
        return SupplierAddress(
          number: '${m['addressNo'] ?? ''}',
          street: '${m['street'] ?? ''}',
          district: '${m['district'] ?? ''}',
          country: '${m['country'] ?? ''}',
        );
      }
    } on FormatException {
      // Plain text address.
    }
    return SupplierAddress(street: raw);
  }

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }
}
