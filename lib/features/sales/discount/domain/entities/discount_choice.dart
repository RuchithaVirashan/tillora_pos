/// What the discount dialog returns to the till.
class DiscountChoice {
  const DiscountChoice({required this.percent, required this.wholeSale});

  final int percent;
  final bool wholeSale;
}
