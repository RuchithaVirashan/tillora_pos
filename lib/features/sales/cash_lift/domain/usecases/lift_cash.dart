import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/session/access_rights.dart';
import '../../../../../core/session/user_session.dart';
import '../repositories/cash_lift_repository.dart';

class LiftCash {
  const LiftCash(this._repository);
  final CashLiftRepository _repository;

  Future<Result<void>> call(UserSession session, int amountCents) async {
    if (!session.access.can(AccessRights.cashLift)) return const Err(PermissionFailure('You do not have cash lift access'));
    if (amountCents <= 0) return const Err(ValidationFailure('Enter the amount to lift'));
    return _repository.liftCash(logId: session.logId ?? 0, amountCents: amountCents);
  }
}
