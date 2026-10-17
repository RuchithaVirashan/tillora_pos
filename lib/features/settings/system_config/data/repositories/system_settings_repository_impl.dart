import 'package:printing/printing.dart';

import '../../../../../core/config/terminal_info.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../infrastructure/database/dao/sys_config_dao.dart';
import '../../../../../infrastructure/hardware/hardware_registry.dart';
import '../../domain/entities/system_settings.dart';
import '../../domain/repositories/system_settings_repository.dart';

class SystemSettingsRepositoryImpl implements SystemSettingsRepository {
  SystemSettingsRepositoryImpl(this._config, this._terminal);

  final SysConfigDao _config;
  final TerminalInfoHolder _terminal;

  static const _keys = ['terminalName', 'maximumQuantity', 'AutoPrint', 'CardPay', 'ageRefusal', 'posprinter', 'labelprinter', 'paperWidth'];

  @override
  List<int> get paperWidths => SystemPrinter.paperWidths;

  @override
  Future<Result<SystemSettings>> settings() => _guard(() async {
    final v = await _config.getMany(_keys);
    String? printer(String key) => (v[key]?.trim().isEmpty ?? true) ? null : v[key]!.trim();
    final info = _terminal.value;
    return SystemSettings(
      terminalName: v['terminalName'] ?? info.terminalName,
      maxQuantity: int.tryParse(v['maximumQuantity'] ?? '') ?? info.maxQuantity,
      autoPrint: v['AutoPrint']?.toUpperCase() == 'ON',
      cardPayments: (v['CardPay'] ?? 'Enabled') == 'Enabled',
      ageCheck: (v['ageRefusal'] ?? 'Enabled') == 'Enabled',
      receiptPrinter: printer('posprinter'),
      labelPrinter: printer('labelprinter'),
      paperWidthMm: int.tryParse(v['paperWidth'] ?? '') ?? 80,
    );
  });

  @override
  Future<Result<void>> save(SystemSettings s) => _guard(() async {
    String onOff(bool on) => on ? 'ON' : 'OFF';
    String enabled(bool on) => on ? 'Enabled' : 'Disabled';
    final values = {
      'terminalName': s.terminalName,
      'maximumQuantity': '${s.maxQuantity}',
      'AutoPrint': onOff(s.autoPrint),
      'CardPay': enabled(s.cardPayments),
      'ageRefusal': enabled(s.ageCheck),
      'posprinter': s.receiptPrinter ?? '',
      'labelprinter': s.labelPrinter ?? '',
      'paperWidth': '${s.paperWidthMm}',
    };
    for (final MapEntry(:key, :value) in values.entries) {
      await _config.set(key, value);
    }
    _terminal.value = _terminal.value.copyWith(
      terminalName: s.terminalName,
      maxQuantity: s.maxQuantity,
      autoPrint: s.autoPrint,
      cardPayments: s.cardPayments,
      ageCheckEnabled: s.ageCheck,
    );
  });

  @override
  Future<Result<List<String>>> printers() async {
    try {
      final info = await Printing.info();
      if (!info.canListPrinters) return const Ok([]);
      final list = await Printing.listPrinters();
      return Ok([for (final p in list) p.name]..sort());
    } catch (e) {
      return Err(HardwareFailure('Could not list printers: $e'));
    }
  }

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }
}
