import 'package:equatable/equatable.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/cart.dart';
import '../entities/sellable_item.dart';
import '../repositories/sales_repository.dart';

class ScanParams {
  const ScanParams(this.barcode, {required this.cart, required this.quantity, required this.maxQuantity});

  final String barcode;
  final Cart cart;
  final int quantity;
  final int maxQuantity;
}

/// The found item plus anything the cashier must be told before it is added.
class ScanOutcome extends Equatable {
  const ScanOutcome({required this.item, this.expired = false, this.stockLeft});

  final SellableItem item;
  final bool expired;

  /// Set when this sale would leave 2 or fewer in stock.
  final int? stockLeft;

  bool get needsAgeCheck => item.ageLimit > 0;

  @override
  List<Object?> get props => [item, expired, stockLeft];
}

/// Looks up a scanned or typed code and runs the checks on every scan:
/// not found, weighed items, expiry, quantity limit, low stock.
class ScanItem implements UseCase<ScanOutcome, ScanParams> {
  const ScanItem(this._repository);

  final SalesRepository _repository;

  static const _lowStockAt = 2;

  @override
  Future<Result<ScanOutcome>> call(ScanParams params) async {
    final code = params.barcode.trim();
    if (code.isEmpty) return const Err(ValidationFailure('Scan or type a barcode'));

    final found = await _repository.findByBarcode(code);
    if (found case Err(:final failure)) return Err(failure);
    final item = (found as Ok<SellableItem?>).value;
    if (item == null) return Err(ValidationFailure('No product found for $code'));

    final inCart = params.cart.lines.where((l) => l.sameAs(item)).fold(0, (n, l) => n + l.quantity);
    if (inCart + params.quantity > params.maxQuantity) {
      return Err(ValidationFailure('Maximum quantity per line is ${params.maxQuantity}'));
    }

    final stock = item.stock;
    final left = (stock != null && !params.cart.refund) ? stock - inCart - params.quantity : null;
    return Ok(ScanOutcome(
      item: item,
      expired: item.isExpiredOn(DateTime.now()),
      stockLeft: left != null && left <= _lowStockAt ? left : null,
    ));
  }
}
