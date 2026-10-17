import 'dart:typed_data';

import '../../../../../core/errors/result.dart';
import '../entities/receipt_settings.dart';

abstract interface class ReceiptSettingsRepository {
  Future<Result<ReceiptSettings>> settings();

  Future<Result<void>> saveText({required String header, required String footer});

  /// Keeps a copy of the image with the app data. Returns its path.
  Future<Result<String>> setLogo(Uint8List bytes, String extension);

  Future<Result<void>> removeLogo();
}
