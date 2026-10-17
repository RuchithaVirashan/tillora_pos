import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../entities/pos_message.dart';
import '../repositories/pos_message_repository.dart';

class GetPosMessages {
  const GetPosMessages(this._repository);
  final PosMessageRepository _repository;

  Future<Result<List<PosMessage>>> call(MessageType type) => _repository.messages(type);
}

class GetPosMessageCounts {
  const GetPosMessageCounts(this._repository);
  final PosMessageRepository _repository;

  Future<Result<Map<MessageType, int>>> call() => _repository.counts();
}

/// Adds a reason ([existing] null) or renames one. Reasons are unique
/// within their type, ignoring case.
class SavePosMessage {
  const SavePosMessage(this._repository);
  final PosMessageRepository _repository;

  static const maxLength = 60;

  Future<Result<void>> call(MessageType type, String text, {PosMessage? existing, required List<PosMessage> all}) async {
    final t = text.trim();
    if (t.isEmpty) return const Err(ValidationFailure('Enter the reason'));
    if (t.length > maxLength) return const Err(ValidationFailure('Keep the reason under $maxLength characters'));
    if (all.any((m) => m.id != existing?.id && m.text.toLowerCase() == t.toLowerCase())) {
      return Err(ValidationFailure('"$t" is already a ${type.label} reason'));
    }
    return existing == null ? _repository.add(type, t) : _repository.update(existing.id, t);
  }
}

/// The till always needs at least one reason to pick.
class DeletePosMessage {
  const DeletePosMessage(this._repository);
  final PosMessageRepository _repository;

  Future<Result<void>> call(MessageType type, PosMessage message, {required List<PosMessage> all}) async {
    if (all.length <= 1) return Err(ValidationFailure('Keep at least one ${type.label} reason'));
    return _repository.delete(message.id);
  }
}
