import 'package:equatable/equatable.dart';

/// Stored as `promotions.promotionType`.
enum PromoType {
  /// Any [Promotion.qty] items from the group sell for the amount.
  buyXGetY('Buy X Get Y Free', 'Customer buys QTY items and pays Amount.', ['Group 1']),

  /// One of each bundle item, together, sell for the amount.
  bundle('Bundle Offer', 'All bundle items together sell for Amount.', ['Bundle items']),

  /// One item from each of the three groups sells for the amount.
  mealDeal(
    'Meal Deal',
    'Please add products to groups 1, 2, and 3 for Meal Deal. Same product cannot be used in multiple groups.',
    ['Group 1 · Main', 'Group 2 · Snack', 'Group 3 · Drink'],
  );

  const PromoType(this.label, this.note, this.groupNames);
  final String label;
  final String note;

  /// Group ids are 1-based positions in this list.
  final List<String> groupNames;

  /// Unknown labels, including the older 'Any For', read as [buyXGetY].
  static PromoType fromLabel(String label) => values.where((t) => t.label == label).firstOrNull ?? buyXGetY;
}

class PromoProduct extends Equatable {
  const PromoProduct({required this.productId, required this.barcode, required this.description, required this.priceCents});

  final int productId;
  final String barcode;
  final String description;
  final int priceCents;

  @override
  List<Object?> get props => [productId, barcode, description, priceCents];
}

class Promotion extends Equatable {
  const Promotion({
    this.id,
    required this.description,
    required this.type,
    required this.start,
    required this.end,
    required this.qty,
    required this.amountCents,
    this.groups = const {},
  });

  /// Null until saved.
  final int? id;
  final String description;
  final PromoType type;

  /// Whole days; the promotion runs from [start] to the end of [end].
  final DateTime start;
  final DateTime end;
  final int qty;
  final int amountCents;

  /// Products by group id (1-based).
  final Map<int, List<PromoProduct>> groups;

  Iterable<PromoProduct> get products => groups.values.expand((g) => g);

  Promotion copyWith({int? qty, Map<int, List<PromoProduct>>? groups}) => Promotion(
    id: id,
    description: description,
    type: type,
    start: start,
    end: end,
    qty: qty ?? this.qty,
    amountCents: amountCents,
    groups: groups ?? this.groups,
  );

  @override
  List<Object?> get props => [id, description, type, start, end, qty, amountCents, groups];
}

/// A row on the promotion list.
typedef PromotionSummary = ({int id, String description, PromoType type, int amountCents, DateTime start, DateTime end, int itemCount});
