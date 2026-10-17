import 'dart:typed_data';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/platform/customer_display.dart';
import '../repositories/display_settings_repository.dart';

class GetDisplaySettings {
  const GetDisplaySettings(this._repository);
  final DisplaySettingsRepository _repository;

  Future<Result<({bool enabled, DisplayStyle style})>> call() => _repository.settings();
}

class SaveDisplayStyle {
  const SaveDisplayStyle(this._repository);
  final DisplaySettingsRepository _repository;

  static const minSeconds = 2, maxSeconds = 600;

  Future<Result<void>> call(DisplayStyle style) async {
    if (style.advertSeconds < minSeconds || style.advertSeconds > maxSeconds) {
      return const Err(ValidationFailure('Image duration must be between $minSeconds and $maxSeconds seconds'));
    }
    if (!DisplayStyle.fontSizes.contains(style.fontSize)) return const Err(ValidationFailure('Choose a font size'));
    return _repository.saveStyle(style);
  }
}

/// Adds an advert image after the others and saves the style.
class AddAdvert {
  const AddAdvert(this._repository);
  final DisplaySettingsRepository _repository;

  static const extensions = ['png', 'jpg', 'jpeg'];
  static const maxAdverts = 12;
  static const maxBytes = 10 * 1024 * 1024;

  Future<Result<DisplayStyle>> call(DisplayStyle style, Uint8List bytes, String extension) async {
    final ext = extension.toLowerCase();
    if (!extensions.contains(ext)) return const Err(ValidationFailure('Choose a PNG or JPG image'));
    if (bytes.length > maxBytes) return const Err(ValidationFailure('Choose an image under 10 MB'));
    if (style.adverts.length >= maxAdverts) return const Err(ValidationFailure('Up to $maxAdverts adverts can be shown'));
    final stored = await _repository.storeAdvert(bytes, ext);
    if (stored case Err(:final failure)) return Err(failure);
    final next = DisplayStyle(
      adverts: [...style.adverts, (stored as Ok<String>).value],
      advertSeconds: style.advertSeconds,
      fontSize: style.fontSize,
      split: style.split,
    );
    return switch (await _repository.saveStyle(next)) {
      Ok() => Ok(next),
      Err(:final failure) => Err(failure),
    };
  }
}

/// Removes advert images and saves the style.
class RemoveAdverts {
  const RemoveAdverts(this._repository);
  final DisplaySettingsRepository _repository;

  Future<Result<DisplayStyle>> call(DisplayStyle style, Set<String> remove) async {
    if (remove.isEmpty) return const Err(ValidationFailure('Select the images to delete'));
    final next = DisplayStyle(
      adverts: [for (final a in style.adverts) if (!remove.contains(a)) a],
      advertSeconds: style.advertSeconds,
      fontSize: style.fontSize,
      split: style.split,
    );
    final saved = await _repository.saveStyle(next);
    if (saved case Err(:final failure)) return Err(failure);
    await _repository.deleteAdverts(remove);
    return Ok(next);
  }
}
