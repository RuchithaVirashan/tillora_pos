import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../domain/entities/payment_type.dart';
import '../../domain/repositories/payment_type_repository.dart';

class PaymentTypeRepositoryImpl implements PaymentTypeRepository {
  PaymentTypeRepositoryImpl(this._db);

  final Database _db;

  @override
  Future<Result<List<PaymentType>>> enabledTypes() async {
    try {
      final rows = await _db.query('paymentType', where: 'enabled = 1', orderBy: 'id');
      return Ok([
        for (final r in rows)
          PaymentType(id: r['id'] as int, name: r['payment_name'] as String, imagePath: r['image_path'] as String),
      ]);
    } catch (e) {
      return Err(DatabaseFailure('Could not load payment types: $e'));
    }
  }
}
