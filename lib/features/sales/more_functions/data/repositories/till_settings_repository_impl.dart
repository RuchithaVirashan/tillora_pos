import '../../../../../core/config/terminal_info.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/platform/customer_display.dart';
import '../../../../../infrastructure/database/dao/sys_config_dao.dart';
import '../../domain/repositories/till_settings_repository.dart';

class TillSettingsRepositoryImpl implements TillSettingsRepository {
  TillSettingsRepositoryImpl(this._config, this._terminal, this._display);

  final SysConfigDao _config;
  final TerminalInfoHolder _terminal;
  final CustomerDisplay _display;

  @override
  Future<Result<void>> setAutoPrint(bool on) async {
    try {
      await _config.set('AutoPrint', on ? 'ON' : 'OFF');
      _terminal.value = _terminal.value.copyWith(autoPrint: on);
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseFailure('Could not save Auto Print: $e'));
    }
  }

  @override
  Future<Result<void>> setCustomerDisplay(bool on) async {
    if (!_display.isSupported) return const Err(HardwareFailure('No customer display on this device'));
    try {
      on ? await _display.open() : await _display.close();
    } catch (e) {
      return Err(HardwareFailure('Customer display could not ${on ? 'open' : 'close'}: $e'));
    }
    try {
      await _config.set('customerDisplay', on ? 'ON' : 'OFF');
      _terminal.value = _terminal.value.copyWith(customerDisplay: on);
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseFailure('Could not save the customer display setting: $e'));
    }
  }
}
