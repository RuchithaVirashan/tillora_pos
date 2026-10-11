import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../domain/repositories/payout_repository.dart';

class PayoutRepositoryImpl implements PayoutRepository {
  PayoutRepositoryImpl(this._db);

  final Database _db;

  @override
  Future<Result<List<String>>> reasons() async {
    try {
      final rows = await _db.query('payoutItems', columns: ['PayoutName'], orderBy: 'PayoutID');
      return Ok([for (final r in rows) r['PayoutName'] as String]);
    } catch (e) {
      return Err(DatabaseFailure('Could not load payout items: $e'));
    }
  }
}
