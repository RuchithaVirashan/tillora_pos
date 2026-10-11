import '../../../../../core/errors/result.dart';

abstract interface class TillSettingsRepository {
  Future<Result<void>> setAutoPrint(bool on);

  /// Opens or closes the customer display and remembers the choice.
  Future<Result<void>> setCustomerDisplay(bool on);
}
