import 'package:equatable/equatable.dart';

/// Where a cart line came from. Stock is only updated for [product].
enum ItemSource {
  product,
  lottery,
  news,
  manual,

  /// Sold by weight; the line price is the weighed amount.
  weighed,

  /// Negative line for an item or sale discount; not counted as an item.
  discount,

  /// Negative line for cash paid out of the drawer.
  payout,
}

/// Something that can go in the cart: a scanned product, quick item,
/// lottery ticket, newspaper, or a manual/department entry.
class SellableItem extends Equatable {
  const SellableItem({
    required this.description,
    required this.barcode,
    required this.priceCents,
    required this.departmentId,
    this.departmentName = '',
    this.productId,
    this.vat = 0,
    this.ageLimit = 0,
    this.stock,
    this.expiryDate,
    this.source = ItemSource.product,
  });

  final int? productId;
  final String description;
  final String barcode;
  final int priceCents;
  final int departmentId;
  final String departmentName;
  final double vat;

  /// Minimum customer age; 0 when the item has no age restriction.
  final int ageLimit;
  final int? stock;
  final DateTime? expiryDate;
  final ItemSource source;

  /// Expired when the expiry date is today or earlier.
  bool isExpiredOn(DateTime day) {
    final expiry = expiryDate;
    if (expiry == null) return false;
    return !DateTime(expiry.year, expiry.month, expiry.day).isAfter(DateTime(day.year, day.month, day.day));
  }

  @override
  List<Object?> get props => [productId, description, barcode, priceCents, departmentId, source];
}
