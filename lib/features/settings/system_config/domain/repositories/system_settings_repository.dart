import '../../../../../core/errors/result.dart';
import '../entities/system_settings.dart';

abstract interface class SystemSettingsRepository {
  Future<Result<SystemSettings>> settings();

  /// Saves and applies the settings to the running till.
  Future<Result<void>> save(SystemSettings settings);

  /// Printers installed on this computer, by name.
  Future<Result<List<String>>> printers();

  /// Roll widths the receipt printer can use, in mm.
  List<int> get paperWidths;
}
