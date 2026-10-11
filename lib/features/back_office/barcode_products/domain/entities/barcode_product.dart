import 'package:equatable/equatable.dart';

/// A product sold by scanning its barcode.
class BarcodeProduct extends Equatable {
  const BarcodeProduct({
    this.id,
    required this.barcode,
    required this.description,
    required this.priceCents,
    required this.departmentId,
    this.departmentName = '',
    this.subDepartmentId,
    this.vat = 0,
    this.stock = 0,
    this.ageLimit = 0,
    this.secondaryBarcode,
    this.caseBarcode,
    this.unitsPerCase = 1,
    this.costPerCaseCents = 0,
    this.quickItem = false,
    this.inPromotion = false,
  });

  /// Null until saved.
  final int? id;
  final String barcode;
  final String description;
  final int priceCents;
  final int? departmentId;
  final String departmentName;
  final int? subDepartmentId;

  /// Percent, e.g. 18 for 18%.
  final double vat;
  final int stock;

  /// Minimum customer age; 0 when unrestricted.
  final int ageLimit;
  final String? secondaryBarcode;
  final String? caseBarcode;
  final int unitsPerCase;
  final int costPerCaseCents;
  final bool quickItem;
  final bool inPromotion;

  /// One unit's cost including VAT, from the case cost.
  int get costPriceCents => unitCost(costPerCaseCents, unitsPerCase, vat);

  int get marginCents => margin(priceCents, costPriceCents);

  static int unitCost(int costPerCaseCents, int unitsPerCase, double vat) =>
      unitsPerCase <= 0 ? 0 : (costPerCaseCents / unitsPerCase * (1 + vat / 100)).round();

  /// Zero when selling at or below cost.
  static int margin(int priceCents, int costCents) => priceCents > costCents ? priceCents - costCents : 0;

  @override
  List<Object?> get props => [
    id, barcode, description, priceCents, departmentId, departmentName, subDepartmentId, vat, stock, ageLimit,
    secondaryBarcode, caseBarcode, unitsPerCase, costPerCaseCents, quickItem, inPromotion,
  ];
}
