import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../infrastructure/database/dao/sys_config_dao.dart';
import '../../domain/entities/receipt_settings.dart';
import '../../domain/repositories/receipt_settings_repository.dart';

class ReceiptSettingsRepositoryImpl implements ReceiptSettingsRepository {
  ReceiptSettingsRepositoryImpl(this._config);

  final SysConfigDao _config;

  static const _header = 'receiptHeader', _footer = 'receiptFooter', _logo = 'receiptLogo';

  @override
  Future<Result<ReceiptSettings>> settings() => _guard(() async {
    final v = await _config.getMany([_header, _footer, _logo]);
    final logo = v[_logo];
    return ReceiptSettings(header: v[_header] ?? '', footer: v[_footer] ?? '', logoPath: logo == null || logo.isEmpty ? null : logo);
  });

  @override
  Future<Result<void>> saveText({required String header, required String footer}) => _guard(() async {
    await _config.set(_header, header);
    await _config.set(_footer, footer);
  });

  /// A new file name each time, so the old logo can be removed safely.
  @override
  Future<Result<String>> setLogo(Uint8List bytes, String extension) => _guard(() async {
    final dir = Directory(p.join((await getApplicationSupportDirectory()).path, 'receipt'));
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, 'logo_${DateTime.now().millisecondsSinceEpoch}.$extension'));
    await file.writeAsBytes(bytes, flush: true);
    final old = await _config.get(_logo);
    await _config.set(_logo, file.path);
    await _delete(old);
    return file.path;
  });

  @override
  Future<Result<void>> removeLogo() => _guard(() async {
    final old = await _config.get(_logo);
    await _config.set(_logo, '');
    await _delete(old);
  });

  static Future<void> _delete(String? path) async {
    if (path == null || path.isEmpty) return;
    final f = File(path);
    if (await f.exists()) await f.delete();
  }

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }
}
