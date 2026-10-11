import 'package:equatable/equatable.dart';

/// One line on the customer display.
class DisplayLine extends Equatable {
  const DisplayLine({required this.name, required this.quantity, required this.priceCents, required this.amountCents});

  final String name;

  /// 0 for discount lines, which show no quantity or unit price.
  final int quantity;
  final int priceCents;
  final int amountCents;

  Map<String, Object> toJson() => {'n': name, 'q': quantity, 'p': priceCents, 'a': amountCents};

  factory DisplayLine.fromJson(Map<String, Object?> j) => DisplayLine(
    name: j['n'] as String,
    quantity: j['q'] as int,
    priceCents: j['p'] as int,
    amountCents: j['a'] as int,
  );

  @override
  List<Object?> get props => [name, quantity, priceCents, amountCents];
}

/// Everything the customer display shows at one moment.
class DisplayFrame extends Equatable {
  const DisplayFrame({
    required this.companyName,
    this.lines = const [],
    this.itemCount = 0,
    this.totalCents = 0,
    this.paidCents = 0,
    this.changeCents = 0,
    this.refund = false,
    this.complete = false,
  });

  final String companyName;
  final List<DisplayLine> lines;
  final int itemCount;
  final int totalCents;
  final int paidCents;
  final int changeCents;
  final bool refund;
  final bool complete;

  bool get idle => lines.isEmpty;

  Map<String, Object> toJson() => {
    'company': companyName,
    'lines': [for (final l in lines) l.toJson()],
    'items': itemCount,
    'total': totalCents,
    'paid': paidCents,
    'change': changeCents,
    'refund': refund,
    'complete': complete,
  };

  factory DisplayFrame.fromJson(Map<String, Object?> j) => DisplayFrame(
    companyName: j['company'] as String,
    lines: [for (final l in j['lines'] as List) DisplayLine.fromJson((l as Map).cast<String, Object?>())],
    itemCount: j['items'] as int,
    totalCents: j['total'] as int,
    paidCents: j['paid'] as int,
    changeCents: j['change'] as int,
    refund: j['refund'] as bool,
    complete: j['complete'] as bool,
  );

  @override
  List<Object?> get props => [companyName, lines, itemCount, totalCents, paidCents, changeCents, refund, complete];
}

/// The second, customer-facing screen. Implemented in
/// `infrastructure/hardware`; a no-op where there is no second window.
abstract interface class CustomerDisplay {
  bool get isSupported;
  bool get isOpen;
  Future<void> open();
  Future<void> close();

  /// Shows [frame]; ignored while the display is closed.
  Future<void> show(DisplayFrame frame);
}
