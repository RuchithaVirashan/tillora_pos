import 'package:equatable/equatable.dart';

import 'sellable_item.dart';

class CartLine extends Equatable {
  const CartLine({required this.item, required this.quantity});

  final SellableItem item;
  final int quantity;

  int get amountCents => item.priceCents * quantity;

  CartLine withQuantity(int quantity) => CartLine(item: item, quantity: quantity);

  /// A discount line added by a running promotion.
  bool get isPromotion => item.barcode.startsWith(Cart.promotionCodePrefix);

  /// The promotion behind a [isPromotion] line.
  int? get promotionId => isPromotion ? int.tryParse(item.barcode.substring(Cart.promotionCodePrefix.length)) : null;

  /// Same product at the same price merges into one line.
  bool sameAs(SellableItem other) =>
      item.barcode == other.barcode && item.description == other.description && item.priceCents == other.priceCents;

  @override
  List<Object?> get props => [item, quantity];
}

/// How a tender was paid. [other] carries the payment type name and id
/// from Payment Type Manager.
class Tender extends Equatable {
  const Tender.cash(this.amountCents) : method = cashMethod, typeId = null;
  const Tender.card(this.amountCents) : method = cardMethod, typeId = null;
  const Tender.other(this.method, this.typeId, this.amountCents);

  static const cashMethod = 'Cash';
  static const cardMethod = 'Card';

  final String method;
  final int? typeId;
  final int amountCents;

  @override
  List<Object?> get props => [method, typeId, amountCents];
}

/// The sale in progress. Immutable: every change returns a new cart.
///
/// Money is held in integer cents so totals never drift.
class Cart extends Equatable {
  const Cart({this.lines = const [], this.selected = -1, this.refund = false, this.tenders = const []});

  /// Newest first.
  final List<CartLine> lines;
  final int selected;
  final bool refund;
  final List<Tender> tenders;

  static const empty = Cart();

  bool get isEmpty => lines.isEmpty;
  int get itemCount => lines.fold(0, (n, l) => l.item.source == ItemSource.discount ? n : n + l.quantity);

  static const itemDiscountCode = '888888';
  static const saleDiscountCode = '999999';
  static const _itemDiscountPrefix = 'Item Discount ';

  /// Barcode of a promotion discount line, followed by the promotion id.
  static const promotionCodePrefix = 'PROMO-';

  /// Positive for a sale, negative for a refund.
  int get totalCents {
    final sum = lines.fold(0, (s, l) => s + l.amountCents);
    return refund ? -sum : sum;
  }

  int get paidCents => tenders.fold(0, (s, t) => s + t.amountCents);

  /// What is still owed (always ≥ 0, in absolute terms for refunds).
  int get dueCents {
    final due = totalCents.abs() - paidCents;
    return due > 0 ? due : 0;
  }

  int get changeCents => isPaid ? paidCents - totalCents.abs() : 0;

  bool get isPaid => lines.isNotEmpty && paidCents >= totalCents.abs();

  CartLine? get selectedLine => selected >= 0 && selected < lines.length ? lines[selected] : null;

  Cart add(SellableItem item, int quantity) {
    final index = lines.indexWhere((l) => l.sameAs(item));
    final next = [...lines];
    if (index >= 0) {
      next[index] = next[index].withQuantity(next[index].quantity + quantity);
      return _copy(lines: next, selected: index);
    }
    return _copy(lines: [CartLine(item: item, quantity: quantity), ...next], selected: 0);
  }

  Cart select(int index) => _copy(selected: index.clamp(-1, lines.length - 1));

  /// Removes the line and the item discount attached to it.
  Cart removeAt(int index) {
    final next = [...lines];
    if (_discountIndexFor(index) case final d?) next.removeAt(d);
    next.removeAt(index);
    return _copy(lines: next, selected: next.isEmpty ? -1 : index.clamp(0, next.length - 1));
  }

  Cart setQuantity(int index, int quantity) {
    if (quantity <= 0) return removeAt(index);
    final next = [...lines];
    next[index] = next[index].withQuantity(quantity);
    return _copy(lines: next);
  }

  /// Puts a percentage discount on the line at [index], directly below it,
  /// replacing any discount already there.
  Cart applyItemDiscount(int index, int percent) {
    final line = lines[index];
    final discount = CartLine(
      quantity: 1,
      item: SellableItem(
        description: '$_itemDiscountPrefix${line.item.description}',
        barcode: itemDiscountCode,
        priceCents: -_percentOf(line.amountCents, percent),
        departmentId: line.item.departmentId,
        departmentName: line.item.departmentName,
        source: ItemSource.discount,
      ),
    );
    final next = [...lines];
    if (_discountIndexFor(index) case final d?) {
      next[d] = discount;
    } else {
      next.insert(index + 1, discount);
    }
    return _copy(lines: next, selected: index);
  }

  /// Puts a percentage discount on the whole sale, replacing an earlier one.
  Cart applySaleDiscount(int percent) {
    final rest = lines.where((l) => l.item.barcode != saleDiscountCode).toList();
    final base = rest.fold(0, (s, l) => s + l.amountCents);
    final discount = CartLine(
      quantity: 1,
      item: SellableItem(
        description: 'Sale Discount $percent%',
        barcode: saleDiscountCode,
        priceCents: -_percentOf(base, percent),
        departmentId: 0,
        source: ItemSource.discount,
      ),
    );
    return _copy(lines: [discount, ...rest], selected: 0);
  }

  /// Sale total before any sale discount, for the discount dialog.
  int get saleBaseCents =>
      lines.where((l) => l.item.barcode != saleDiscountCode).fold(0, (s, l) => s + l.amountCents);

  /// The line at [index] has an item discount below it.
  bool hasItemDiscount(int index) => _discountIndexFor(index) != null;

  /// Replaces the promotion lines with [promotions], kept at the top under
  /// any sale discount. The selected line stays selected.
  Cart withPromotions(List<CartLine> promotions) {
    final rest = lines.where((l) => !l.isPromotion).toList();
    final at = rest.isNotEmpty && rest.first.item.barcode == saleDiscountCode ? 1 : 0;
    final next = [...rest]..insertAll(at, promotions);
    if (next.length == lines.length && Iterable.generate(next.length).every((i) => next[i] == lines[i])) return this;
    final current = selectedLine;
    final selectedNow = current == null ? -1 : next.indexOf(current);
    return _copy(lines: next, selected: selectedNow >= 0 ? selectedNow : (next.isEmpty ? -1 : 0));
  }

  int? _discountIndexFor(int index) {
    final d = index + 1;
    if (d >= lines.length) return null;
    final item = lines[d].item;
    final owner = '$_itemDiscountPrefix${lines[index].item.description}';
    return item.barcode == itemDiscountCode && item.description == owner ? d : null;
  }

  static int _percentOf(int cents, int percent) => (cents * percent / 100).round();

  Cart withTender(Tender tender) => _copy(tenders: [...tenders, tender]);

  Cart toggleRefund() => Cart(lines: lines, selected: selected, refund: !refund);

  Cart _copy({List<CartLine>? lines, int? selected, List<Tender>? tenders}) => Cart(
    lines: lines ?? this.lines,
    selected: selected ?? this.selected,
    refund: refund,
    tenders: tenders ?? this.tenders,
  );

  @override
  List<Object?> get props => [lines, selected, refund, tenders];
}
