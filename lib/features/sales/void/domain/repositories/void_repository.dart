import '../../../../../core/errors/result.dart';
import '../../../cart/domain/entities/cart.dart';

enum VoidKind { line, sale }

/// What the void dialog works on: the selected line (if any) and the
/// whole sale, so the cashier can switch between Void Line and Void Sale.
class VoidRequest {
  const VoidRequest({required this.cart, this.kind = VoidKind.line});

  final Cart cart;
  final VoidKind kind;

  CartLine? get line => cart.selectedLine;

  List<CartLine> linesFor(VoidKind kind) => kind == VoidKind.line ? [?line] : cart.lines;

  int amountFor(VoidKind kind) =>
      kind == VoidKind.line ? (line?.amountCents ?? 0) : cart.totalCents.abs();

  String labelFor(VoidKind kind) => kind == VoidKind.line && line != null
      ? '${line!.item.description} × ${line!.quantity}'
      : 'Whole sale · ${cart.itemCount} items';
}

abstract interface class VoidRepository {
  Future<Result<List<String>>> reasons(VoidKind kind);

  /// Voids already used this shift, for the role's limit.
  Future<Result<int>> usedThisShift(VoidKind kind, int logId);

  Future<Result<void>> record(VoidKind kind, {required String reason, required int logId, required List<CartLine> lines});
}
