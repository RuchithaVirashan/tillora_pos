import '../../../../../core/errors/result.dart';

abstract interface class NoSaleRepository {
  Future<Result<List<String>>> reasons();

  Future<Result<int>> usedThisShift(int logId);

  /// Records the reason and opens the cash drawer.
  Future<Result<void>> openDrawer({required String reason, required int logId});
}
