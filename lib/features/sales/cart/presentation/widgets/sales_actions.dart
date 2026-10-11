import 'package:material_ui/material_ui.dart';

/// Everything the till's buttons can do that leaves the cart cubit:
/// opening dialogs, logging out, ending the shift. Built by the screen.
class SalesActions {
  const SalesActions({
    required this.voidLine,
    required this.voidSale,
    required this.hold,
    required this.priceCheck,
    required this.otherPayment,
    required this.noSale,
    required this.transactions,
    required this.menu,
    required this.logout,
    required this.endShift,
    required this.weight,
    required this.discount,
    required this.payout,
  });

  final VoidCallback voidLine;
  final VoidCallback voidSale;
  final VoidCallback hold;
  final VoidCallback priceCheck;
  final VoidCallback otherPayment;
  final VoidCallback noSale;
  final VoidCallback transactions;
  final VoidCallback menu;
  final VoidCallback logout;
  final VoidCallback endShift;
  final VoidCallback weight;
  final VoidCallback discount;
  final VoidCallback payout;
}
