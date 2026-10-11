import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/db_date.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../infrastructure/hardware/hardware_registry.dart';
import '../../domain/repositories/cash_lift_repository.dart';

class CashLiftRepositoryImpl implements CashLiftRepository {
  CashLiftRepositoryImpl(this._db, this._hardware);

  final Database _db;
  final HardwareRegistry _hardware;

  @override
  Future<Result<void>> liftCash({required int logId, required int amountCents}) async {
    try {
      await _db.insert('cashLift', {'logId': logId, 'liftAt': DbDate.now(), 'amount': Money.fromCents(amountCents)});
    } catch (e) {
      return Err(DatabaseFailure('Could not record the cash lift: $e'));
    }
    try {
      await _hardware.receiptPrinter.openCashDrawer();
      return const Ok(null);
    } catch (e) {
      return Err(HardwareFailure('Cash lift saved, but the drawer did not open: $e'));
    }
  }
}
