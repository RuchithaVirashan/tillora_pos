import 'dart:typed_data';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../entities/receipt_settings.dart';
import '../repositories/receipt_settings_repository.dart';

class GetReceiptSettings {
  const GetReceiptSettings(this._repository);
  final ReceiptSettingsRepository _repository;

  Future<Result<ReceiptSettings>> call() => _repository.settings();
}

class SaveReceiptText {
  const SaveReceiptText(this._repository);
  final ReceiptSettingsRepository _repository;

  /// Blank lines and trailing spaces are dropped.
  static String tidy(String text) => [for (final l in text.split('\n')) if (l.trim().isNotEmpty) l.trim()].join('\n');

  Future<Result<void>> call({required String header, required String footer}) async {
    final h = tidy(header);
    if (h.isEmpty) return const Err(ValidationFailure('Enter at least one header line, such as the shop name'));
    return _repository.saveText(header: h, footer: tidy(footer));
  }
}

class SetReceiptLogo {
  const SetReceiptLogo(this._repository);
  final ReceiptSettingsRepository _repository;

  static const extensions = ['png', 'jpg', 'jpeg'];

  /// Logos are small; anything larger slows printing.
  static const maxBytes = 2 * 1024 * 1024;

  Future<Result<String>> call(Uint8List bytes, String extension) async {
    final ext = extension.toLowerCase();
    if (!extensions.contains(ext)) return const Err(ValidationFailure('Choose a PNG or JPG image'));
    if (bytes.length > maxBytes) return const Err(ValidationFailure('Choose an image under 2 MB'));
    return _repository.setLogo(bytes, ext);
  }
}

class RemoveReceiptLogo {
  const RemoveReceiptLogo(this._repository);
  final ReceiptSettingsRepository _repository;

  Future<Result<void>> call() => _repository.removeLogo();
}
