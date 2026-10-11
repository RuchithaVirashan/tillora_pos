import 'package:equatable/equatable.dart';

import '../../../cart/domain/entities/cart.dart';

class HeldSale extends Equatable {
  const HeldSale({required this.id, required this.heldAt, required this.itemCount, required this.totalCents});

  final int id;
  final DateTime heldAt;
  final int itemCount;
  final int totalCents;

  @override
  List<Object?> get props => [id];
}

/// What the Hold & Recall dialog returns to the till.
sealed class HoldOutcome {
  const HoldOutcome();
}

final class SaleHeld extends HoldOutcome {
  const SaleHeld();
}

final class SaleRecalled extends HoldOutcome {
  const SaleRecalled(this.lines);

  final List<CartLine> lines;
}
