import 'package:equatable/equatable.dart';

/// One payment towards a transaction: the method and the amount handed over.
typedef PaymentPart = ({String method, int amountCents});

class ShiftTransaction extends Equatable {
  const ShiftTransaction({
    required this.id,
    required this.at,
    required this.method,
    required this.totalCents,
    required this.itemCount,
    this.payments = const [],
    this.changeCents = 0,
  });

  final int id;
  final DateTime at;

  /// 'Cash', 'Card', 'PartPay' or a payment type name.
  final String method;
  final int totalCents;
  final int itemCount;

  /// The one or two payments, in the order they were taken.
  final List<PaymentPart> payments;

  /// Given back in cash.
  final int changeCents;

  bool get isRefund => totalCents < 0;
  bool get isPartPay => method == 'PartPay';

  /// "Card + Cash" for a split payment, else the payment type.
  String get methodLabel => isPartPay && payments.isNotEmpty ? payments.map((p) => p.method).join(' + ') : method;

  @override
  List<Object?> get props => [id, method, totalCents, payments, changeCents];
}

class TransactionLine extends Equatable {
  const TransactionLine({required this.description, required this.quantity, required this.amountCents});

  final String description;
  final int quantity;
  final int amountCents;

  @override
  List<Object?> get props => [description, quantity, amountCents];
}

/// A pay type a transaction can be switched to.
class PayTypeOption extends Equatable {
  const PayTypeOption(this.name, [this.id]);

  final String name;
  final int? id;

  @override
  List<Object?> get props => [name, id];
}
