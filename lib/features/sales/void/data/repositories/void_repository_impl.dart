import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../infrastructure/database/dao/pos_records_dao.dart';
import '../../../cart/domain/entities/cart.dart';
import '../../domain/repositories/void_repository.dart';

class VoidRepositoryImpl implements VoidRepository {
  VoidRepositoryImpl(this._records);

  final PosRecordsDao _records;

  static String _type(VoidKind kind) => kind == VoidKind.line ? PosRecordsDao.voidLine : PosRecordsDao.voidSale;

  @override
  Future<Result<List<String>>> reasons(VoidKind kind) => _guard(() => _records.reasons(_type(kind)));

  @override
  Future<Result<int>> usedThisShift(VoidKind kind, int logId) => _guard(() => _records.countForShift(_type(kind), logId));

  @override
  Future<Result<void>> record(VoidKind kind, {required String reason, required int logId, required List<CartLine> lines}) =>
      _guard(() => _records.record(
        type: _type(kind),
        reason: reason,
        logId: logId,
        // Same item shape as held sales.
        items: [
          for (final l in lines)
            {
              'item_name': l.item.description,
              'quantity': l.quantity,
              'price': Money.fromCents(l.item.priceCents),
              'amount': Money.fromCents(l.amountCents),
              'cloudSync': 0,
              'barcode': l.item.barcode,
            },
        ],
      ));

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }
}
