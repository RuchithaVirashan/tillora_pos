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

/// How the left (advert) and right (basket) sides share the display.
enum DisplaySplit {
  sixtyForty('60/40', 6, 4),
  half('50/50', 1, 1),
  fortySixty('40/60', 2, 3),
  thirtySeventy('30/70', 3, 7);

  const DisplaySplit(this.label, this.left, this.right);
  final String label;
  final int left;
  final int right;

  static DisplaySplit fromLabel(String? label) => values.where((s) => s.label == label).firstOrNull ?? sixtyForty;
}

/// Look of the customer display, set in Settings > Second Screen.
class DisplayStyle extends Equatable {
  const DisplayStyle({this.adverts = const [], this.advertSeconds = 8, this.fontSize = defaultFontSize, this.split = DisplaySplit.sixtyForty});

  static const defaultFontSize = 20;
  static const fontSizes = [16, 18, 20, 22, 24, 28, 32];

  /// Image files shown in turn on the left side; empty shows the shop name.
  final List<String> adverts;
  final int advertSeconds;

  /// Text size of the basket, 20 being the standard size.
  final int fontSize;
  final DisplaySplit split;

  double get textScale => fontSize / defaultFontSize;

  Map<String, Object> toJson() => {'ads': adverts, 'secs': advertSeconds, 'font': fontSize, 'split': split.label};

  factory DisplayStyle.fromJson(Map<String, Object?> j) => DisplayStyle(
    adverts: [for (final a in (j['ads'] as List?) ?? const []) '$a'],
    advertSeconds: j['secs'] as int? ?? 8,
    fontSize: j['font'] as int? ?? defaultFontSize,
    split: DisplaySplit.fromLabel(j['split'] as String?),
  );

  @override
  List<Object?> get props => [adverts, advertSeconds, fontSize, split];
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
    this.style = const DisplayStyle(),
  });

  final String companyName;
  final List<DisplayLine> lines;
  final int itemCount;
  final int totalCents;
  final int paidCents;
  final int changeCents;
  final bool refund;
  final bool complete;
  final DisplayStyle style;

  bool get idle => lines.isEmpty;

  DisplayFrame withStyle(DisplayStyle style) => DisplayFrame(
    companyName: companyName,
    lines: lines,
    itemCount: itemCount,
    totalCents: totalCents,
    paidCents: paidCents,
    changeCents: changeCents,
    refund: refund,
    complete: complete,
    style: style,
  );

  Map<String, Object> toJson() => {
    'company': companyName,
    'lines': [for (final l in lines) l.toJson()],
    'items': itemCount,
    'total': totalCents,
    'paid': paidCents,
    'change': changeCents,
    'refund': refund,
    'complete': complete,
    'style': style.toJson(),
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
    style: j['style'] is Map ? DisplayStyle.fromJson((j['style'] as Map).cast<String, Object?>()) : const DisplayStyle(),
  );

  @override
  List<Object?> get props => [companyName, lines, itemCount, totalCents, paidCents, changeCents, refund, complete, style];
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

  /// Applies [style] to every frame from now on, redrawing the current one.
  Future<void> applyStyle(DisplayStyle style);
}
