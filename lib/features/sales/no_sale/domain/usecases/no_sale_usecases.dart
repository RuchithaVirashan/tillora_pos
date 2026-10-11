import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/session/access_rights.dart';
import '../../../../../core/session/user_session.dart';
import '../repositories/no_sale_repository.dart';

class NoSaleOptions {
  const NoSaleOptions(this.reasons, this.remaining);

  final List<String> reasons;
  final int remaining;
}

class GetNoSaleOptions {
  const GetNoSaleOptions(this._repository);

  final NoSaleRepository _repository;

  Future<Result<NoSaleOptions>> call(UserSession session) async {
    if (!session.access.can(AccessRights.noSale)) return const Err(PermissionFailure('You do not have no sale access'));
    final reasons = await _repository.reasons();
    final used = await _repository.usedThisShift(session.logId ?? 0);
    return switch ((reasons, used)) {
      (Ok(value: final r), Ok(value: final u)) => Ok(NoSaleOptions(r, session.access.limit(AccessRights.noSaleCount) - u)),
      (Err(:final failure), _) || (_, Err(:final failure)) => Err(failure),
    };
  }
}

class OpenDrawerNoSale {
  const OpenDrawerNoSale(this._repository);

  final NoSaleRepository _repository;

  Future<Result<void>> call({required String reason, required int logId}) =>
      _repository.openDrawer(reason: reason, logId: logId);
}
