import 'package:intl/intl.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/utils/db_date.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../infrastructure/database/dao/products_dao.dart';
import '../../domain/repositories/price_change_repository.dart';

class PriceChangeRepositoryImpl implements PriceChangeRepository {
  PriceChangeRepositoryImpl(this._products);

  final ProductsDao _products;

  @override
  Future<Result<PricedProduct?>> find(String query) => _guard(() async {
    final rows = await _products.search(query, limit: 1);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return (
      productId: r['id'] as int,
      barcode: r['barcode'] as String,
      description: r['description'] as String,
      priceCents: Money.toCents(r['price'] as num),
      expiryDate: DbDate.tryParse(r['expiryDate'] as String?),
    );
  });

  @override
  Future<Result<void>> updatePrice(int productId, int priceCents) =>
      _guard(() => _products.updatePrice(productId, Money.fromCents(priceCents)));

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
