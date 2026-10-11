import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/session/access_rights.dart';
import '../../../../../core/session/user_session.dart';
import '../../../cart/domain/entities/cart.dart';
import '../repositories/void_repository.dart';

class VoidOptions {
  const VoidOptions(this.reasons, this.remaining);

  final List<String> reasons;
  final int remaining;
}

/// Reasons to pick from and how many voids the user has left this shift.
class GetVoidOptions {
  const GetVoidOptions(this._repository);

  final VoidRepository _repository;

  Future<Result<VoidOptions>> call(VoidKind kind, UserSession session) async {
    final (flag, countFlag) = _flags(kind);
    if (!session.access.can(flag)) return const Err(PermissionFailure('You do not have void access'));

    final reasons = await _repository.reasons(kind);
    final used = await _repository.usedThisShift(kind, session.logId ?? 0);
    return switch ((reasons, used)) {
      (Ok(value: final r), Ok(value: final u)) => Ok(VoidOptions(r, session.access.limit(countFlag) - u)),
      (Err(:final failure), _) || (_, Err(:final failure)) => Err(failure),
    };
  }
}

/// Records the void with its reason. The caller then removes the lines.
class RecordVoid {
  const RecordVoid(this._repository);

  final VoidRepository _repository;

  Future<Result<void>> call(VoidKind kind, {required String reason, required int logId, required List<CartLine> lines}) =>
      _repository.record(kind, reason: reason, logId: logId, lines: lines);
}

(String, String) _flags(VoidKind kind) => kind == VoidKind.line
    ? (AccessRights.voidLine, AccessRights.voidLineCount)
    : (AccessRights.voidSale, AccessRights.voidSaleCount);
