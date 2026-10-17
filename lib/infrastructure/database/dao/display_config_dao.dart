import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/platform/customer_display.dart';

/// Customer display settings in `displayConfig` (key/value rows).
class DisplayConfigDao {
  DisplayConfigDao(this._db);

  final Database _db;

  static const _images = 'imagePath', _seconds = 'imageDuration', _font = 'fontSize', _split = 'splitRatio';

  Future<DisplayStyle> style() async {
    final rows = await _db.query('displayConfig', columns: ['Parameter', 'Value']);
    final v = {for (final r in rows) r['Parameter'] as String: '${r['Value']}'};
    List<String> images() {
      try {
        return [for (final p in jsonDecode(v[_images] ?? '[]') as List) '$p'];
      } on FormatException {
        // Older rows hold a single path.
        return [if ((v[_images] ?? '').isNotEmpty) v[_images]!];
      }
    }

    final font = int.tryParse(v[_font] ?? '');
    return DisplayStyle(
      adverts: images(),
      advertSeconds: int.tryParse(v[_seconds] ?? '') ?? 8,
      fontSize: DisplayStyle.fontSizes.contains(font) ? font! : DisplayStyle.defaultFontSize,
      split: DisplaySplit.fromLabel(v[_split]),
    );
  }

  Future<void> saveStyle(DisplayStyle style) => _db.transaction((txn) async {
    final values = {
      _images: jsonEncode(style.adverts),
      _seconds: '${style.advertSeconds}',
      _font: '${style.fontSize}',
      _split: style.split.label,
    };
    for (final MapEntry(:key, :value) in values.entries) {
      final updated = await txn.update('displayConfig', {'Value': value, 'cloudSync': 0}, where: 'Parameter = ?', whereArgs: [key]);
      if (updated == 0) await txn.insert('displayConfig', {'Parameter': key, 'Value': value});
    }
  });
}
