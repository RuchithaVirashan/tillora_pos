/// Field rules shared by product, barcode and newspaper forms.
/// Ported from the old app's validate_service.dart and barcode checks.
abstract final class Validators {
  static final _digitsOnly = RegExp(r'^\d+$');

  /// Main, secondary and case barcodes: digits only, no blanks or spaces.
  static String? barcode(String? value, {bool allowEmpty = false}) {
    final v = value ?? '';
    if (v.isEmpty) return allowEmpty ? null : 'Please enter barcode';
    if (v.trim().isEmpty || !_digitsOnly.hasMatch(v)) {
      return 'Numbers only — remove letters and spaces';
    }
    return null;
  }

  /// Newspaper ISSN barcodes: 10 digits, magazines: 11 digits.
  static String? issn(String? value, {required bool magazine}) {
    final length = magazine ? 11 : 10;
    final v = value ?? '';
    if (!_digitsOnly.hasMatch(v) || v.length != length) {
      return 'ISSN must be exactly $length digits.';
    }
    return null;
  }

  static String? required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Please fill the field' : null;
}
