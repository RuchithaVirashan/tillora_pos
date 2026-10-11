import 'package:material_ui/material_ui.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../domain/entities/cart.dart';
import '../bloc/sales_cubit.dart';
import '../widgets/cart_panel.dart';
import '../widgets/sales_actions.dart';
import '../widgets/till_controls.dart';

/// Sales.dc.html at 1440×900: cart on the left, till controls on the right.
class SalesDesktopLayout extends StatelessWidget {
  const SalesDesktopLayout({super.key, required this.state, required this.cubit, required this.actions});

  final SalesState state;
  final SalesCubit cubit;
  final SalesActions actions;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final narrow = MediaQuery.sizeOf(context).width < 1300;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: narrow ? 460 : 560,
            child: Column(
              children: [
                EntryBar(state: state, onSearch: actions.priceCheck),
                const SizedBox(height: 12),
                Expanded(child: CartTable(cart: state.cart, onSelect: cubit.selectLine, dense: narrow)),
                const SizedBox(height: 12),
                TotalsCard(state: state),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: narrow ? 240 : 300,
                        child: QuickItemsGrid(items: state.quickItems, onPick: cubit.addQuickItem, onMore: actions.moreQuickItems),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            FunctionStrip(cubit: cubit, actions: actions),
                            const SizedBox(height: 8),
                            Expanded(child: TillKeypad(onKey: cubit.key)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 196,
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: ActionKeys(cart: state.cart, cubit: cubit, actions: actions)),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: narrow ? 340 : 420,
                        child: PaymentKeys(cart: state.cart, cubit: cubit, actions: actions),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Phones and small tablets: cart and totals on top, till controls in tabs
/// below, CASH / CARD always visible.
class SalesMobileLayout extends StatelessWidget {
  const SalesMobileLayout({super.key, required this.state, required this.cubit, required this.actions});

  final SalesState state;
  final SalesCubit cubit;
  final SalesActions actions;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            EntryBar(state: state, onSearch: actions.priceCheck),
            const SizedBox(height: 8),
            Expanded(flex: 5, child: CartTable(cart: state.cart, onSelect: cubit.selectLine, dense: true)),
            const SizedBox(height: 8),
            TotalsCard(state: state),
            const SizedBox(height: 8),
            TabBar(
              labelColor: c.primary,
              unselectedLabelColor: c.muted,
              indicatorColor: c.primary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800),
              tabs: const [Tab(text: 'Keypad'), Tab(text: 'Quick items'), Tab(text: 'Actions')],
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 6,
              child: TabBarView(
                children: [
                  TillKeypad(onKey: cubit.key),
                  QuickItemsGrid(items: state.quickItems, onPick: cubit.addQuickItem, onMore: actions.moreQuickItems, columns: 3, rows: 4),
                  Column(
                    children: [
                      Expanded(child: ActionKeys(cart: state.cart, cubit: cubit, actions: actions)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 52,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: PosButton(label: 'Rs 500', style: PosButtonStyle.note, onPressed: () => cubit.pay(const Tender.cash(50000)))),
                            const SizedBox(width: 8),
                            Expanded(
                              child: PosButton(label: 'OTHER PAYMENT', style: PosButtonStyle.outline, fontSize: 13, onPressed: actions.otherPayment),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: PosButton(
                      label: state.cart.refund ? 'REFUND CASH' : 'CASH',
                      fontSize: 18,
                      style: PosButtonStyle.success,
                      onPressed: cubit.payCash,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: PosButton(label: 'CARD', fontSize: 18, style: PosButtonStyle.primary, onPressed: cubit.payCard)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
