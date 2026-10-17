/// One product on the stock list.
typedef StockEntry = ({
  int productId,
  String barcode,
  String description,
  int stock,
  String department,
  String subDepartment,
  int priceCents,
});

/// The filtered list plus the value of everything it matches.
typedef StockList = ({List<StockEntry> entries, int matched, int grossTotalCents});

/// Why stock was adjusted, stored as `stockAdjustment.adjustmentType`.
/// [sign] is +1 for stock coming in, -1 for going out, 0 for either.
enum StockAdjustReason {
  delivery('Delivery', 1),
  count('Count', 0),
  damaged('Damaged', -1),
  expired('Expired', -1);

  const StockAdjustReason(this.label, this.sign);
  final String label;
  final int sign;
}
