import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../domain/entities/pos_message.dart';
import '../../domain/repositories/pos_message_repository.dart';

class PosMessageRepositoryImpl implements PosMessageRepository {
  PosMessageRepositoryImpl(this._db);

  final Database _db;

  @override
  Future<Result<List<PosMessage>>> messages(MessageType type) => _guard(() async {
    final rows = await _db.query('posMessages', columns: ['mid', 'value'], where: 'parameter = ?', whereArgs: [type.key], orderBy: 'mid');
    return [for (final r in rows) (id: r['mid'] as int, text: r['value'] as String)];
  });

  @override
  Future<Result<Map<MessageType, int>>> counts() => _guard(() async {
    final rows = await _db.rawQuery('SELECT parameter, COUNT(*) AS n FROM posMessages GROUP BY parameter');
    final byKey = {for (final r in rows) r['parameter'] as String: r['n'] as int};
    return {for (final t in MessageType.values) t: byKey[t.key] ?? 0};
  });

  @override
  Future<Result<void>> add(MessageType type, String text) => _guard(() => _db.insert('posMessages', {'parameter': type.key, 'value': text}));

  @override
  Future<Result<void>> update(int id, String text) =>
      _guard(() => _db.update('posMessages', {'value': text, 'cloudSync': 0}, where: 'mid = ?', whereArgs: [id]));

  @override
  Future<Result<void>> delete(int id) => _guard(() => _db.delete('posMessages', where: 'mid = ?', whereArgs: [id]));

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }
}
