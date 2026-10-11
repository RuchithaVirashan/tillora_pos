import 'package:equatable/equatable.dart';

enum ExceptionType {
  voidLine('Void Line', 'voiditem'),
  voidSale('Void Sale', 'voidsale'),
  noSale('No Sale', 'nosale'),
  refund('Refund', null),
  ageRefusal('Age Refusal', 'agerefusal');

  const ExceptionType(this.label, this.recordType);
  final String label;

  /// `posRecords.Rec_Type`; null for refunds, which are transactions.
  final String? recordType;
}

class ExceptionItem extends Equatable {
  const ExceptionItem({required this.name, required this.quantity, required this.priceCents, required this.amountCents});

  final String name;
  final int quantity;
  final int priceCents;
  final int amountCents;

  @override
  List<Object?> get props => [name, quantity, priceCents, amountCents];
}

class ExceptionRecord extends Equatable {
  const ExceptionRecord({
    required this.id,
    required this.at,
    required this.userName,
    required this.reason,
    required this.amountCents,
    required this.items,
  });

  /// Record id, or the transaction id for refunds.
  final int id;
  final DateTime at;
  final String userName;
  final String reason;
  final int amountCents;
  final List<ExceptionItem> items;

  @override
  List<Object?> get props => [id, at];
}
