import '../../../../../core/config/terminal_info.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../infrastructure/database/dao/sys_config_dao.dart';
import '../../domain/repositories/till_settings_repository.dart';

class TillSettingsRepositoryImpl implements TillSettingsRepository {
  TillSettingsRepositoryImpl(this._config, this._terminal);

  final SysConfigDao _config;
  final TerminalInfoHolder _terminal;

  @override
  Future<Result<void>> setAutoPrint(bool on) async {
    try {
      await _config.set('AutoPrint', on ? 'ON' : 'OFF');
      final t = _terminal.value;
      _terminal.value = TerminalInfo(
        companyName: t.companyName,
        terminalName: t.terminalName,
        autoPrint: on,
        ageCheckEnabled: t.ageCheckEnabled,
        maxQuantity: t.maxQuantity,
      );
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseFailure('Could not save Auto Print: $e'));
    }
  }
}
