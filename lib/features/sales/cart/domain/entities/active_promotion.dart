import 'package:equatable/equatable.dart';

import '../../../../back_office/promotions/domain/entities/promotion.dart';

/// A promotion running today, as the till applies it.
class ActivePromotion extends Equatable {
  const ActivePromotion({
    required this.id,
    required this.description,
    required this.type,
    required this.qty,
    required this.amountCents,
    required this.groups,
  });

  final int id;
  final String description;
  final PromoType type;

  /// Items per set for [PromoType.buyXGetY].
  final int qty;

  /// Price of one set.
  final int amountCents;

  /// Product ids by group (1-based).
  final Map<int, Set<int>> groups;

  Set<int> get productIds => {for (final g in groups.values) ...g};

  @override
  List<Object?> get props => [id, description, type, qty, amountCents, groups];
}
