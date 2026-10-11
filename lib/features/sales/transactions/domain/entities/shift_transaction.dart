import 'package:equatable/equatable.dart';

class ShiftTransaction extends Equatable {
  const ShiftTransaction({
    required this.id,
    required this.at,
    required this.method,
    required this.methodId,
    required this.totalCents,
    required this.itemCount,
  });

  final int id;
  final DateTime at;

  /// 'Cash', 'Card', 'PartPay' or a payment type name.
  final String method;
  final int? methodId;
  final int totalCents;
  final int itemCount;

  bool get isRefund => totalCents < 0;
  bool get isPartPay => method == 'PartPay';

  @override
  List<Object?> get props => [id, method, totalCents];
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
