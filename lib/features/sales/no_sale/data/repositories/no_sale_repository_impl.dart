import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../infrastructure/database/dao/pos_records_dao.dart';
import '../../../../../infrastructure/hardware/hardware_registry.dart';
import '../../domain/repositories/no_sale_repository.dart';

class NoSaleRepositoryImpl implements NoSaleRepository {
  NoSaleRepositoryImpl(this._records, this._hardware);

  final PosRecordsDao _records;
  final HardwareRegistry _hardware;

  @override
  Future<Result<List<String>>> reasons() => _guard(() => _records.reasons(PosRecordsDao.noSale));

  @override
  Future<Result<int>> usedThisShift(int logId) => _guard(() => _records.countForShift(PosRecordsDao.noSale, logId));

  @override
  Future<Result<void>> openDrawer({required String reason, required int logId}) async {
    final recorded = await _guard(() => _records.record(type: PosRecordsDao.noSale, reason: reason, logId: logId));
    if (recorded case Err()) return recorded;
    try {
      await _hardware.receiptPrinter.openCashDrawer();
      return const Ok(null);
    } catch (e) {
      return Err(HardwareFailure('Cash drawer did not open: $e'));
    }
  }

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }
}
