import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../../core/config/terminal_info.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/platform/customer_display.dart';
import '../../../../../infrastructure/database/dao/display_config_dao.dart';
import '../../domain/repositories/display_settings_repository.dart';

class DisplaySettingsRepositoryImpl implements DisplaySettingsRepository {
  DisplaySettingsRepositoryImpl(this._config, this._display, this._terminal);

  final DisplayConfigDao _config;
  final CustomerDisplay _display;
  final TerminalInfoHolder _terminal;

  @override
  Future<Result<({bool enabled, DisplayStyle style})>> settings() =>
      _guard(() async => (enabled: _terminal.value.customerDisplay, style: await _config.style()));

  @override
  Future<Result<void>> saveStyle(DisplayStyle style) => _guard(() async {
    await _config.saveStyle(style);
    await _display.applyStyle(style);
  });

  @override
  Future<Result<String>> storeAdvert(Uint8List bytes, String extension) => _guard(() async {
    final dir = Directory(p.join((await getApplicationSupportDirectory()).path, 'adverts'));
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, 'advert_${DateTime.now().millisecondsSinceEpoch}.$extension'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  });

  @override
  Future<Result<void>> deleteAdverts(Iterable<String> paths) => _guard(() async {
    for (final path in paths) {
      final f = File(path);
      if (await f.exists()) await f.delete();
    }
  });

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }
}
