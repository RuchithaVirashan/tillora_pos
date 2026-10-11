import 'package:equatable/equatable.dart';

class ShiftSummary extends Equatable {
  const ShiftSummary({
    required this.userName,
    required this.startedAt,
    required this.endedAt,
    required this.drawerFloatCents,
    required this.salesByMethod,
    required this.refundsCents,
    required this.cashLiftsCents,
    required this.salesByDepartment,
    required this.salesByHour,
    required this.transactionCount,
    required this.noSaleCount,
    required this.voidLineCount,
    required this.voidSaleCount,
  });

  final String userName;
  final DateTime startedAt;
  final DateTime endedAt;
  final int drawerFloatCents;

  /// Net takings per payment type ('Cash', 'Card', 'PartPay', other names).
  final Map<String, int> salesByMethod;
  final int refundsCents;
  final int cashLiftsCents;
  final Map<String, int> salesByDepartment;

  /// Hour of day (0–23) → takings.
  final Map<int, int> salesByHour;
  final int transactionCount;
  final int noSaleCount;
  final int voidLineCount;
  final int voidSaleCount;

  int get cashCents => salesByMethod['Cash'] ?? 0;

  /// Float plus net cash taken, minus cash lifted out.
  int get expectedInDrawerCents => drawerFloatCents + cashCents - cashLiftsCents;

  int get totalCents => salesByMethod.values.fold(0, (a, b) => a + b);

  @override
  List<Object?> get props => [startedAt, endedAt, totalCents, drawerFloatCents];
}
