import '../../../../../core/errors/result.dart';
import '../entities/exchange_rates.dart';

abstract interface class ExchangeRateRepository {
  Future<Result<ExchangeRates>> rates();

  /// Replaces every rate and stamps today as the update date.
  Future<Result<ExchangeRates>> save(Map<String, double> rates);
}
