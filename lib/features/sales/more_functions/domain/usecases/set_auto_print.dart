import '../../../../../core/errors/result.dart';
import '../repositories/till_settings_repository.dart';

class SetAutoPrint {
  const SetAutoPrint(this._repository);
  final TillSettingsRepository _repository;

  Future<Result<void>> call(bool on) => _repository.setAutoPrint(on);
}
