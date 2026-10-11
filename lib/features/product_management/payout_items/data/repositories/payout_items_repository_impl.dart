import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../domain/repositories/payout_items_repository.dart';

class PayoutItemsRepositoryImpl implements PayoutItemsRepository {
  PayoutItemsRepositoryImpl(this._db);

  final Database _db;

  @override
  Future<Result<List<PayoutItem>>> items() => _guard(() async {
    final rows = await _db.query('payoutItems', columns: ['PayoutID', 'PayoutName'], orderBy: 'PayoutID');
    return [for (final r in rows) (id: r['PayoutID'] as int, name: r['PayoutName'] as String)];
  });

  @override
  Future<Result<void>> add(String name) => _guard(() => _db.insert('payoutItems', {'PayoutName': name}));

  @override
  Future<Result<void>> delete(int id) => _guard(() => _db.delete('payoutItems', where: 'PayoutID = ?', whereArgs: [id]));

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }
}
