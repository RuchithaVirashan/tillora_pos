import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../entities/system_settings.dart';
import '../repositories/system_settings_repository.dart';

class GetSystemSettings {
  const GetSystemSettings(this._repository);
  final SystemSettingsRepository _repository;

  Future<Result<SystemSettings>> call() => _repository.settings();
}

class SaveSystemSettings {
  const SaveSystemSettings(this._repository);
  final SystemSettingsRepository _repository;

  static const maxTerminalName = 20;

  Future<Result<void>> call(SystemSettings s) async {
    final name = s.terminalName.trim();
    if (name.isEmpty) return const Err(ValidationFailure('Enter the terminal name'));
    if (name.length > maxTerminalName) return const Err(ValidationFailure('Keep the terminal name under $maxTerminalName characters'));
    if (s.maxQuantity < 1 || s.maxQuantity > 9999) return const Err(ValidationFailure('Maximum quantity must be between 1 and 9999'));
    if (!_repository.paperWidths.contains(s.paperWidthMm)) return const Err(ValidationFailure('Choose a paper size'));
    return _repository.save(s.copyWith(terminalName: name));
  }
}

class GetInstalledPrinters {
  const GetInstalledPrinters(this._repository);
  final SystemSettingsRepository _repository;

  Future<Result<List<String>>> call() => _repository.printers();

  List<int> get paperWidths => _repository.paperWidths;
}
