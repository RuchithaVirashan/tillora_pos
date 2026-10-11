import '../../../../../core/errors/result.dart';

abstract interface class TillSettingsRepository {
  Future<Result<void>> setAutoPrint(bool on);
}
