import 'package:equatable/equatable.dart';

/// A product sold without a barcode, shown as a key on the sales screen.
/// Price 0 means the cashier types the price.
class NonBarcodeItem extends Equatable {
  const NonBarcodeItem({
    required this.itemId,
    required this.description,
    required this.priceCents,
    required this.departmentId,
    this.departmentName = '',
    this.ageLimit = 0,
  });

  final int itemId;
  final String description;
  final int priceCents;
  final int departmentId;
  final String departmentName;
  final int ageLimit;

  @override
  List<Object?> get props => [itemId, description, priceCents, departmentId, ageLimit];
}
