import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/db_date.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../infrastructure/database/dao/pos_records_dao.dart';
import '../../../../../infrastructure/database/dao/receipt_dao.dart';
import '../../../../../infrastructure/hardware/hardware_registry.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/sellable_item.dart';
import '../../domain/repositories/sales_repository.dart';
import '../datasources/sales_local_data_source.dart';

class SalesRepositoryImpl implements SalesRepository {
  SalesRepositoryImpl(this._local, this._hardware, this._records, this._receipts);

  final SalesLocalDataSource _local;
  final HardwareRegistry _hardware;
  final PosRecordsDao _records;
  final ReceiptDao _receipts;

  /// Department names change rarely; loaded once instead of per line.
  Map<int, String>? _departments;

  Future<Map<int, String>> _departmentNames() async => _departments ??= await _local.departmentNames();

  @override
  Future<Result<SellableItem?>> findByBarcode(String barcode) async {
    try {
      final row = await _local.findByBarcode(barcode);
      if (row == null) return const Ok(null);
      if ((row['caseBarcode'] as String?)?.toLowerCase() == 'weight') {
        return const Err(ValidationFailure('This is a weighed item — use Weight'));
      }
      return Ok(_toItem(row, await _departmentNames()));
    } catch (e) {
      return Err(DatabaseFailure('Product lookup failed: $e'));
    }
  }

  @override
  Future<Result<List<SellableItem>>> quickItems() async {
    try {
      final departments = await _departmentNames();
      final rows = await _local.quickItems();
      return Ok([for (final r in rows) _toItem(r, departments)]);
    } catch (e) {
      return Err(DatabaseFailure('Could not load quick items: $e'));
    }
  }

  @override
  Future<Result<List<SellableItem>>> weighedProducts(String query) async {
    try {
      final departments = await _departmentNames();
      final rows = await _local.weighedProducts(query);
      return Ok([for (final r in rows) _toItem({...r, 'source': 'product'}, departments)]);
    } catch (e) {
      return Err(DatabaseFailure('Could not load weighed products: $e'));
    }
  }

  @override
  Future<Result<int>> saveSale(Cart cart, {required int logId}) async {
    try {
      return Ok(await _local.saveSale(cart, logId: logId, departments: await _departmentNames()));
    } catch (e) {
      return Err(DatabaseFailure('The sale could not be saved: $e'));
    }
  }

  @override
  Future<Result<void>> openCashDrawer() async {
    try {
      await _hardware.receiptPrinter.openCashDrawer();
      return const Ok(null);
    } catch (e) {
      return Err(HardwareFailure('Cash drawer did not open: $e'));
    }
  }

  @override
  Future<Result<void>> printReceipt(int transactionId, {bool reprint = false}) async {
    try {
      final receipt = await _receipts.forTransaction(transactionId);
      if (receipt == null) return Err(ValidationFailure('Transaction $transactionId was not found'));
      await _hardware.receiptPrinter.printReceipt(reprint ? receipt.asReprint() : receipt);
      return const Ok(null);
    } catch (e) {
      return Err(HardwareFailure('The receipt did not print: $e'));
    }
  }

  @override
  Future<Result<void>> recordAgeRefusal(SellableItem item, {required int logId}) async {
    try {
      await _records.record(
        type: PosRecordsDao.ageRefusal,
        reason: '${item.description} (${item.ageLimit}+)',
        logId: logId,
        items: [
          {'item_name': item.description, 'quantity': 1, 'price': Money.fromCents(item.priceCents), 'barcode': item.barcode},
        ],
      );
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseFailure("Could not record the age refusal: $e"));
    }
  }

  static SellableItem _toItem(Map<String, Object?> r, Map<int, String> departments) {
    final departmentId = (r['departmentId'] as num?)?.toInt() ?? 0;
    return SellableItem(
      productId: r['id'] as int?,
      description: r['description'] as String,
      barcode: r['barcode'] as String,
      priceCents: Money.toCents(r['price'] as num),
      departmentId: departmentId,
      departmentName: departments[departmentId] ?? '',
      vat: (r['vat'] as num?)?.toDouble() ?? 0,
      ageLimit: (r['ageRefusal'] as num?)?.toInt() ?? 0,
      stock: (r['stock'] as num?)?.toInt(),
      expiryDate: DbDate.tryParse(r['expiryDate'] as String?),
      source: switch (r['source']) {
        'lottery' => ItemSource.lottery,
        'news' => ItemSource.news,
        'manual' => ItemSource.manual,
        _ => ItemSource.product,
      },
    );
  }
}
