import 'dart:convert';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/db_date.dart';
import '../../../../../infrastructure/database/dao/sys_config_dao.dart';
import '../../domain/entities/exchange_rates.dart';
import '../../domain/repositories/exchange_rate_repository.dart';

/// Rates live in sysConfig as JSON, with the date they were last changed.
class ExchangeRateRepositoryImpl implements ExchangeRateRepository {
  ExchangeRateRepositoryImpl(this._config);

  final SysConfigDao _config;

  static const _rates = 'exchangeRates', _updated = 'exchangeRatesUpdated';

  @override
  Future<Result<ExchangeRates>> rates() async {
    try {
      final v = await _config.getMany([_rates, _updated]);
      final json = jsonDecode(v[_rates] ?? '{}') as Map<String, Object?>;
      return Ok(ExchangeRates(
        rates: {for (final MapEntry(:key, :value) in json.entries) if (value is num && value > 0) key: value.toDouble()},
        updated: DbDate.tryParse(v[_updated]),
      ));
    } catch (e) {
      return Err(DatabaseFailure('Could not read exchange rates: $e'));
    }
  }

  @override
  Future<Result<ExchangeRates>> save(Map<String, double> rates) async {
    try {
      final now = DateTime.now();
      await _config.set(_rates, jsonEncode(rates));
      await _config.set(_updated, DbDate.format(now));
      return Ok(ExchangeRates(rates: rates, updated: now));
    } catch (e) {
      return Err(DatabaseFailure('Could not save exchange rates: $e'));
    }
  }
}
