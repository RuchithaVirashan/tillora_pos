import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../domain/repositories/payment_type_admin_repository.dart';

class PaymentTypeAdminRepositoryImpl implements PaymentTypeAdminRepository {
  PaymentTypeAdminRepositoryImpl(this._db);

  final Database _db;

  @override
  Future<Result<List<ManagedPaymentType>>> paymentTypes() => _guard(() async {
    final rows = await _db.query('paymentType', columns: ['id', 'payment_name', 'enabled'], orderBy: 'id');
    return [for (final r in rows) (id: r['id'] as int, name: r['payment_name'] as String, enabled: r['enabled'] == 1)];
  });

  @override
  Future<Result<int>> add(String name, {required bool enabled}) =>
      _guard(() => _db.insert('paymentType', {'payment_name': name, 'image_path': '', 'enabled': enabled ? 1 : 0}));

  @override
  Future<Result<void>> update(int id, String name, {required bool enabled}) => _guard(
    () => _db.update('paymentType', {'payment_name': name, 'enabled': enabled ? 1 : 0, 'cloudSync': 0}, where: 'id = ?', whereArgs: [id]),
  );

  /// Payment type ids are stored in the slots; cash (0) and card (-1)
  /// never collide with them.
  @override
  Future<Result<int>> usageCount(int id) => _guard(() async {
    final rows = await _db.rawQuery('SELECT COUNT(*) AS n FROM Transactions WHERE method1Id = ?1 OR method2Id = ?1', [id]);
    return rows.first['n'] as int;
  });

  @override
  Future<Result<void>> delete(int id) => _guard(() => _db.delete('paymentType', where: 'id = ?', whereArgs: [id]));

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }
}
