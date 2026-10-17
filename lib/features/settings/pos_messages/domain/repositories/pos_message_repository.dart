import '../../../../../core/errors/result.dart';
import '../entities/pos_message.dart';

abstract interface class PosMessageRepository {
  /// In the order they show at the till.
  Future<Result<List<PosMessage>>> messages(MessageType type);

  /// How many reasons each type has.
  Future<Result<Map<MessageType, int>>> counts();

  Future<Result<void>> add(MessageType type, String text);

  Future<Result<void>> update(int id, String text);

  Future<Result<void>> delete(int id);
}
