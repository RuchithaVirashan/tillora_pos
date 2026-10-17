import '../../../../back_office/promotions/domain/entities/promotion.dart';
import '../entities/active_promotion.dart';
import '../entities/cart.dart';
import '../entities/sellable_item.dart';

/// Works out the promotion discount lines for a cart.
///
/// Only scanned products count, and not lines that already carry an item
/// discount. Each unit goes towards one promotion at most, and the dearest
/// qualifying units are used first so the customer gets the best saving.
/// Refunds get no promotions.
abstract final class ApplyPromotions {
  static Cart apply(Cart cart, List<ActivePromotion> promotions) => cart.withPromotions(discountLines(cart, promotions));

  static List<CartLine> discountLines(Cart cart, List<ActivePromotion> promotions) {
    if (cart.refund || promotions.isEmpty) return const [];

    // Unit prices still available, dearest first, by product id.
    final pool = <int, List<int>>{};
    for (final (i, line) in cart.lines.indexed) {
      final item = line.item;
      if (item.source != ItemSource.product || item.productId == null || item.priceCents <= 0 || cart.hasItemDiscount(i)) continue;
      pool.putIfAbsent(item.productId!, () => []).addAll(List.filled(line.quantity, item.priceCents));
    }
    if (pool.isEmpty) return const [];
    for (final prices in pool.values) {
      prices.sort((a, b) => b.compareTo(a));
    }

    /// Dearest-first units of [products], as `(productId, price)`.
    List<(int, int)> units(Iterable<int> products) =>
        [for (final id in products) for (final price in pool[id] ?? const <int>[]) (id, price)]..sort((a, b) => b.$2.compareTo(a.$2));

    /// Removes [taken] from the pool and returns their normal price.
    int consume(Iterable<(int, int)> taken) {
      var total = 0;
      for (final (id, price) in taken) {
        pool[id]!.remove(price);
        total += price;
      }
      return total;
    }

    final lines = <CartLine>[];
    for (final promo in promotions) {
      var sets = 0, normal = 0;
      switch (promo.type) {
        case PromoType.buyXGetY:
          if (promo.qty <= 0) continue;
          final eligible = units(promo.productIds);
          sets = eligible.length ~/ promo.qty;
          normal = consume(eligible.take(sets * promo.qty));
        case PromoType.bundle:
          // One of every bundle product per set.
          final ids = promo.productIds;
          sets = ids.isEmpty ? 0 : ids.map((id) => pool[id]?.length ?? 0).reduce((a, b) => a < b ? a : b);
          for (final id in ids) {
            normal += consume(units([id]).take(sets));
          }
        case PromoType.mealDeal:
          // One from each group per set.
          final groups = [for (var g = 1; g <= PromoType.mealDeal.groupNames.length; g++) units(promo.groups[g] ?? const {})];
          sets = groups.map((g) => g.length).reduce((a, b) => a < b ? a : b);
          for (final g in groups) {
            normal += consume(g.take(sets));
          }
      }
      final discount = normal - sets * promo.amountCents;
      // A promotion dearer than the normal price is not applied.
      if (sets == 0 || discount <= 0) continue;
      lines.add(CartLine(
        quantity: 1,
        item: SellableItem(
          description: 'Promo ${promo.description}',
          barcode: '${Cart.promotionCodePrefix}${promo.id}',
          priceCents: -discount,
          departmentId: 0,
          departmentName: 'Promotion',
          source: ItemSource.discount,
        ),
      ));
    }
    return lines;
  }
}
