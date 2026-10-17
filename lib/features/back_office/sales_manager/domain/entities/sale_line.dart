/// A closed shift to pick from.
typedef ShiftOption = ({int logId, String userName, DateTime started, DateTime? ended});

/// One sold line of a past sale.
typedef SaleLine = ({
  int itemId,
  int transactionId,
  String description,
  int quantity,
  int priceCents,
  int amountCents,
  PayKind kind,

  /// The payment type name(s), e.g. 'Cash' or 'Card + Cash'.
  String payment,
});

/// How the sale was paid, for the filter.
enum PayKind {
  cash('Cash'),
  card('Card'),
  partPay('PartPay'),
  other('Other');

  const PayKind(this.label);
  final String label;
}
