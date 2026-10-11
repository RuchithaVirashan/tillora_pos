import 'package:equatable/equatable.dart';

class ReceiptLine extends Equatable {
  const ReceiptLine({required this.name, required this.quantity, required this.priceCents, required this.amountCents});

  final String name;

  /// 0 for discount lines, which print no quantity or unit price.
  final int quantity;
  final int priceCents;
  final int amountCents;

  bool get isDiscount => quantity == 0;

  @override
  List<Object?> get props => [name, quantity, priceCents, amountCents];
}

/// A printed receipt for one saved transaction.
class Receipt extends Equatable {
  const Receipt({
    required this.transactionId,
    required this.at,
    required this.header,
    required this.footer,
    required this.cashier,
    required this.terminal,
    required this.lines,
    required this.itemCount,
    required this.totalCents,
    required this.payments,
    required this.changeCents,
    this.reprint = false,
  });

  final int transactionId;
  final DateTime at;

  /// Shop name and address, one line each.
  final List<String> header;
  final List<String> footer;
  final String cashier;
  final String terminal;
  final List<ReceiptLine> lines;
  final int itemCount;

  /// Negative for a refund.
  final int totalCents;

  /// `(method, cents)` in the order taken.
  final List<(String, int)> payments;
  final int changeCents;

  /// Printed again from Transactions; marked as a copy.
  final bool reprint;

  bool get isRefund => totalCents < 0;

  String get number => '#${transactionId.toString().padLeft(6, '0')}';

  Receipt asReprint() => Receipt(
    transactionId: transactionId,
    at: at,
    header: header,
    footer: footer,
    cashier: cashier,
    terminal: terminal,
    lines: lines,
    itemCount: itemCount,
    totalCents: totalCents,
    payments: payments,
    changeCents: changeCents,
    reprint: true,
  );

  @override
  List<Object?> get props => [transactionId, reprint];
}
