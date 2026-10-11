/// What the payout dialog returns: a reason and the amount paid out.
class PayoutEntry {
  const PayoutEntry(this.name, this.amountCents);

  final String name;
  final int amountCents;
}
