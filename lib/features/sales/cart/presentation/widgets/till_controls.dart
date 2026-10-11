import 'package:material_ui/material_ui.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/sellable_item.dart';
import '../bloc/sales_cubit.dart';
import 'cart_panel.dart';
import 'sales_actions.dart';

const _gap = 8.0;

/// Lays children out in equal rows; each child gives its column span.
class SpanGrid extends StatelessWidget {
  const SpanGrid({super.key, required this.rows});

  final List<List<(int, Widget)>> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: _gap),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < rows[r].length; i++) ...[
                  if (i > 0) const SizedBox(width: _gap),
                  Expanded(flex: rows[r][i].$1, child: rows[r][i].$2),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// 2×5 quick item tiles; empty slots stay blank.
class QuickItemsGrid extends StatelessWidget {
  const QuickItemsGrid({super.key, required this.items, required this.onPick, this.columns = 2, this.rows = 5});

  final List<SellableItem> items;
  final ValueChanged<SellableItem> onPick;
  final int columns;
  final int rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.quickItem,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.quickItemLine),
        ),
        child: Text(
          'No quick items yet.\nMark products as quick items in Back Office.',
          textAlign: TextAlign.center,
          style: TextStyle(color: c.quickItemSub, fontWeight: FontWeight.w700),
        ),
      );
    }
    Widget tile(int i) {
      if (i >= items.length) return const SizedBox.shrink();
      final item = items[i];
      return Material(
        color: c.quickItem,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: c.quickItemLine)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onPick(item),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, height: 1.2, color: c.quickItemInk)),
                const SizedBox(height: 6),
                Text(rs(item.priceCents),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.quickItemSub,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    )),
              ],
            ),
          ),
        ),
      );
    }

    return SpanGrid(rows: [
      for (var r = 0; r < rows; r++) [for (var col = 0; col < columns; col++) (1, tile(r * columns + col))],
    ]);
  }
}

/// Reset Qty / Weight / Prod% / Sale% / PAYOUT.
class FunctionStrip extends StatelessWidget {
  const FunctionStrip({super.key, required this.cubit, required this.actions});

  final SalesCubit cubit;
  final SalesActions actions;

  @override
  Widget build(BuildContext context) {
    Widget k(String label, VoidCallback onTap) =>
        PosButton(label: label, fontSize: 14, style: PosButtonStyle.function, onPressed: onTap);
    return SizedBox(
      height: 52,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, w) in [
            k('Reset Qty', () => cubit.key(SalesCubit.keyResetQty)),
            k('Weight', actions.weight),
            k('Prod%', actions.discount),
            k('Sale%', actions.discount),
            k('PAYOUT', actions.payout),
          ].indexed) ...[
            if (i > 0) const SizedBox(width: _gap),
            Expanded(child: w),
          ],
        ],
      ),
    );
  }
}

/// 4×4 till keypad with a double-height ENTER.
class TillKeypad extends StatelessWidget {
  const TillKeypad({super.key, required this.onKey});

  final ValueChanged<String> onKey;

  @override
  Widget build(BuildContext context) {
    Widget num(String l) => PosButton(label: l, style: PosButtonStyle.number, onPressed: () => onKey(l));
    Widget fn(String l, String semantic) =>
        PosButton(label: l, style: PosButtonStyle.function, semanticLabel: semantic, onPressed: () => onKey(l));
    Widget column(List<Widget> keys) => Expanded(
      child: Column(
        children: [
          for (var i = 0; i < keys.length; i++) ...[if (i > 0) const SizedBox(height: _gap), Expanded(child: keys[i])],
        ],
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        column([num('7'), num('4'), num('1'), num('.')]),
        const SizedBox(width: _gap),
        column([num('8'), num('5'), num('2'), num('0')]),
        const SizedBox(width: _gap),
        column([num('9'), num('6'), num('3'), num('00')]),
        const SizedBox(width: _gap),
        Expanded(
          child: Column(
            children: [
              Expanded(child: fn(SalesCubit.keyDelete, 'Delete')),
              const SizedBox(height: _gap),
              Expanded(child: fn(SalesCubit.keyTimes, 'Set quantity')),
              const SizedBox(height: _gap),
              Expanded(
                flex: 2,
                child: PosButton(
                  label: 'ENTER',
                  fontSize: 20,
                  style: PosButtonStyle.primary,
                  onPressed: () => onKey(SalesCubit.keyEnter),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// VOID LINE · PRICE CHECK · HOLD / VOID SALE · REFUND · MENU
class ActionKeys extends StatelessWidget {
  const ActionKeys({super.key, required this.cart, required this.cubit, required this.actions});

  final Cart cart;
  final SalesCubit cubit;
  final SalesActions actions;

  @override
  Widget build(BuildContext context) {
    Widget b(String l, PosButtonStyle s, VoidCallback onTap) => PosButton(label: l, style: s, fontSize: 14, onPressed: onTap);
    return SpanGrid(rows: [
      [
        (1, b('VOID\nLINE', PosButtonStyle.voidTint, actions.voidLine)),
        (1, b('PRICE\nCHECK', PosButtonStyle.function, actions.priceCheck)),
        (1, b('HOLD', PosButtonStyle.holdTint, actions.hold)),
      ],
      [
        (1, b('VOID\nSALE', PosButtonStyle.voidTint, actions.voidSale)),
        (1, b(cart.refund ? 'SALES' : 'REFUND', cart.refund ? PosButtonStyle.primary : PosButtonStyle.outlineDanger, cubit.toggleRefund)),
        (1, b('MENU', PosButtonStyle.function, actions.menu)),
      ],
    ]);
  }
}

/// Rs 500 · Rs 1,000 · OTHER PAYMENT / CASH · CARD
class PaymentKeys extends StatelessWidget {
  const PaymentKeys({super.key, required this.cart, required this.cubit, required this.actions});

  final Cart cart;
  final SalesCubit cubit;
  final SalesActions actions;

  @override
  Widget build(BuildContext context) {
    Widget b(String l, PosButtonStyle s, VoidCallback onTap, {double size = 18}) =>
        PosButton(label: l, style: s, fontSize: size, onPressed: onTap);
    return SpanGrid(rows: [
      [
        (1, b('Rs 500', PosButtonStyle.note, () => cubit.pay(const Tender.cash(50000)))),
        (1, b('Rs 1,000', PosButtonStyle.note, () => cubit.pay(const Tender.cash(100000)))),
        (2, b('OTHER\nPAYMENT', PosButtonStyle.outline, actions.otherPayment, size: 14)),
      ],
      [
        (1, b(cart.refund ? 'REFUND\nCASH' : 'CASH', PosButtonStyle.success, cubit.payCash)),
        (1, b('CARD', PosButtonStyle.primary, cubit.payCard)),
      ],
    ]);
  }
}
