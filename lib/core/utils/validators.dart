/// Field rules shared by product and barcode forms.
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

  static String? required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Please fill the field' : null;
}
