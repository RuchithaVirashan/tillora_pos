import 'package:equatable/equatable.dart';

enum LabelType {
  /// Shelf label with the barcode.
  barcode('Barcode label'),

  /// Label for a product sold by weight, priced per kg.
  weight('Weight label');

  const LabelType(this.label);
  final String label;
}

enum LabelFormat {
  /// A4 sheet, 3 × 7 labels of 70 × 38 mm, through the print dialog.
  sheet,

  /// One 62 × 29 mm label per page for a QL roll printer.
  roll,
}

class LabelProduct extends Equatable {
  const LabelProduct({
    required this.productId,
    required this.barcode,
    required this.description,
    required this.priceCents,
    this.wasPriceCents,
    this.pluCode,
  });

  final int productId;
  final String barcode;
  final String description;

  /// Per kg for weight labels.
  final int priceCents;

  /// The previous price when it was higher, shown as "Was".
  final int? wasPriceCents;
  final String? pluCode;

  @override
  List<Object?> get props => [productId, barcode, description, priceCents, wasPriceCents, pluCode];
}

/// A product and how many labels to print for it.
typedef LabelLine = ({LabelProduct product, int count});
