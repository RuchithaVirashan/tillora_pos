import 'package:equatable/equatable.dart';

class PriceCheckItem extends Equatable {
  const PriceCheckItem({
    required this.productId,
    required this.description,
    required this.barcode,
    required this.priceCents,
    required this.departmentName,
    required this.stock,
    this.expiryDate,
  });

  final int productId;
  final String description;
  final String barcode;
  final int priceCents;
  final String departmentName;
  final int stock;
  final DateTime? expiryDate;

  @override
  List<Object?> get props => [productId, priceCents, stock, expiryDate];
}
