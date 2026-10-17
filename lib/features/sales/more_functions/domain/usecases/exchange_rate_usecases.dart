import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/session/user_session.dart';
import '../entities/exchange_rates.dart';
import '../repositories/exchange_rate_repository.dart';

class GetExchangeRates {
  const GetExchangeRates(this._repository);
  final ExchangeRateRepository _repository;

  Future<Result<ExchangeRates>> call() => _repository.rates();
}

/// Adds or changes one rate. Only admins keep the rates.
class SetExchangeRate {
  const SetExchangeRate(this._repository);
  final ExchangeRateRepository _repository;

  static final _code = RegExp(r'^[A-Z]{3}$');

  Future<Result<ExchangeRates>> call(ExchangeRates current, String code, double? rupeesPerUnit, {required UserSession session}) async {
    if (session.roleId != Roles.admin) return const Err(PermissionFailure('Only an admin can change exchange rates'));
    final c = code.trim().toUpperCase();
    if (!_code.hasMatch(c)) return const Err(ValidationFailure('Enter a 3 letter currency code, e.g. USD'));
    if (c == ExchangeRates.base) return const Err(ValidationFailure('LKR is the till currency'));
    if (rupeesPerUnit == null || rupeesPerUnit <= 0) return const Err(ValidationFailure('Enter the rupees for one unit'));
    return _repository.save({...current.rates, c: rupeesPerUnit});
  }
}

class RemoveExchangeRate {
  const RemoveExchangeRate(this._repository);
  final ExchangeRateRepository _repository;

  Future<Result<ExchangeRates>> call(ExchangeRates current, String code, {required UserSession session}) async {
    if (session.roleId != Roles.admin) return const Err(PermissionFailure('Only an admin can change exchange rates'));
    return _repository.save({...current.rates}..remove(code));
  }
}
