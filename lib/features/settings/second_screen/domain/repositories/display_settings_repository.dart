import 'dart:typed_data';

import '../../../../../core/errors/result.dart';
import '../../../../../core/platform/customer_display.dart';

abstract interface class DisplaySettingsRepository {
  /// Whether the display opens with Sales, and how it looks.
  Future<Result<({bool enabled, DisplayStyle style})>> settings();

  /// Saves the style and redraws the open display with it.
  Future<Result<void>> saveStyle(DisplayStyle style);

  /// Keeps a copy of the image with the app data. Returns its path.
  Future<Result<String>> storeAdvert(Uint8List bytes, String extension);

  /// Deletes advert files no longer used.
  Future<Result<void>> deleteAdverts(Iterable<String> paths);
}
