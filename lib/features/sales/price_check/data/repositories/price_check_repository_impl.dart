import 'package:intl/intl.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/db_date.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../infrastructure/database/dao/products_dao.dart';
import '../../domain/entities/price_check_item.dart';
import '../../domain/repositories/price_check_repository.dart';

class PriceCheckRepositoryImpl implements PriceCheckRepository {
  PriceCheckRepositoryImpl(this._products);

  final ProductsDao _products;

  @override
  Future<Result<List<PriceCheckItem>>> search(String query) => _guard(() async {
    final rows = await _products.search(query);
    return [
      for (final r in rows)
        PriceCheckItem(
          productId: r['id'] as int,
          description: r['description'] as String,
          barcode: r['barcode'] as String,
          priceCents: Money.toCents(r['price'] as num),
          departmentName: (r['departmentName'] as String?) ?? '',
          stock: (r['stock'] as num?)?.toInt() ?? 0,
          expiryDate: DbDate.tryParse(r['expiryDate'] as String?),
        ),
    ];
  });

  @override
  Future<Result<void>> updatePrice(int productId, int priceCents) =>
      _guard(() => _products.updatePrice(productId, Money.fromCents(priceCents)));

  /// Stored as `yyyy-MM-dd`.
  @override
  Future<Result<void>> setExpiry(int productId, DateTime? date) =>
      _guard(() => _products.setExpiry(productId, date == null ? null : DateFormat('yyyy-MM-dd').format(date)));

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Ok(await run());
    } catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }
}
