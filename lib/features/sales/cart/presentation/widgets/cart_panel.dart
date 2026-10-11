import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../core/widgets/amount_display.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/sellable_item.dart';
import '../bloc/sales_cubit.dart';

String rs(int cents) => Money.lkr(Money.fromCents(cents));

BoxDecoration panelBox(AppColors c) => BoxDecoration(
  color: c.surface,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: c.line),
  boxShadow: c.surface == Colors.white ? const [BoxShadow(color: Color(0x0F101828), blurRadius: 2, offset: Offset(0, 1))] : null,
);

/// QTY + BARCODE fields and the product search button.
class EntryBar extends StatelessWidget {
  const EntryBar({super.key, required this.state, required this.onSearch});

  final SalesState state;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.9, color: c.muted);
    Widget box({required Widget child, required Color border, double width = 2}) => Container(
      height: 50,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: c.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: width),
      ),
      child: child,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: panelBox(c),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 84,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('QTY', style: label),
                const SizedBox(height: 5),
                box(
                  border: c.line,
                  width: 1,
                  child: Center(
                    child: Text('×${state.nextQuantity}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.ink)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BARCODE', style: label),
                const SizedBox(height: 5),
                Semantics(
                  label: 'Barcode',
                  value: state.entry,
                  liveRegion: true,
                  child: box(
                    border: c.primary,
                    child: Text(
                      state.entry.isEmpty ? 'Scan or type a barcode' : state.entry,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                        color: state.entry.isEmpty ? c.muted : c.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: c.primary,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onSearch,
              child: const SizedBox(
                width: 56,
                height: 50,
                child: Icon(Icons.search_rounded, color: Colors.white, size: 22, semanticLabel: 'Search products'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ITEM / QTY / PRICE / AMOUNT table. Tapping a row selects it.
class CartTable extends StatefulWidget {
  const CartTable({super.key, required this.cart, required this.onSelect, this.dense = false});

  final Cart cart;
  final ValueChanged<int> onSelect;
  final bool dense;

  @override
  State<CartTable> createState() => _CartTableState();
}

class _CartTableState extends State<CartTable> {
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(CartTable old) {
    super.didUpdateWidget(old);
    // New items go on top; keep the newest line in view.
    if (widget.cart.lines.length > old.cart.lines.length && _scroll.hasClients) {
      _scroll.animateTo(0, duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cart = widget.cart;
    final head = TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: c.muted);
    final priceWidth = widget.dense ? 84.0 : 104.0;
    final amountWidth = widget.dense ? 96.0 : 118.0;

    return Container(
      decoration: panelBox(c),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: c.tableHead,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: [
                Expanded(child: Text('ITEM', style: head)),
                SizedBox(width: 44, child: Text('QTY', textAlign: TextAlign.center, style: head)),
                SizedBox(width: priceWidth, child: Text('PRICE', textAlign: TextAlign.right, style: head)),
                SizedBox(width: amountWidth, child: Text('AMOUNT', textAlign: TextAlign.right, style: head)),
              ],
            ),
          ),
          Divider(height: 1, color: c.line),
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Sale Cleared', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.ink)),
                        const SizedBox(height: 8),
                        Text('Scan an item or tap a quick item', style: TextStyle(fontSize: 14, color: c.muted)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    itemCount: cart.lines.length,
                    itemExtent: 58,
                    itemBuilder: (context, i) => _row(context, c, cart.lines[i], i, priceWidth, amountWidth),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, AppColors c, CartLine line, int i, double priceWidth, double amountWidth) {
    final selected = i == widget.cart.selected;
    final sign = widget.cart.refund ? '−' : '';
    final isDiscount = line.item.source == ItemSource.discount;
    const nums = [FontFeature.tabularFigures()];
    return Material(
      color: selected ? c.selection : Colors.transparent,
      child: InkWell(
        onTap: () => widget.onSelect(i),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: c.rowLine),
              left: BorderSide(color: selected ? AppColors.amber : Colors.transparent, width: 4),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(line.item.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.ink)),
                    if (line.item.departmentName.isNotEmpty)
                      Text(line.item.departmentName, style: TextStyle(fontSize: 12, color: c.muted)),
                  ],
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(isDiscount ? '' : '${line.quantity}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.ink, fontFeatures: nums)),
              ),
              SizedBox(
                width: priceWidth,
                child: Text(isDiscount ? '' : rs(line.item.priceCents),
                    textAlign: TextAlign.right, style: TextStyle(fontSize: 15, color: c.inkSecondary, fontFeatures: nums)),
              ),
              SizedBox(
                width: amountWidth,
                child: Text('$sign${rs(line.amountCents)}',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.ink, fontFeatures: nums)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Items count, status line and TOTAL / PAID / CHANGE.
class TotalsCard extends StatelessWidget {
  const TotalsCard({super.key, required this.state});

  final SalesState state;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cart = state.cart;
    final done = state.saleComplete;
    final status = done
        ? (cart.refund ? 'Refund complete' : 'Sale complete — hand over change')
        : cart.paidCents > 0
        ? 'Balance due ${rs(cart.dueCents)}'
        : (cart.refund ? 'Refund in progress' : 'Sale in progress');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: panelBox(c),
      child: Column(
        children: [
          DefaultTextStyle(
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.muted),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Items: ${cart.itemCount}'),
                const SizedBox(width: 12),
                Flexible(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(status, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 13,
                child: StatTile(
                  label: 'TOTAL',
                  value: '${cart.refund && cart.totalCents != 0 ? '−' : ''}${rs(cart.totalCents.abs())}',
                  ink: cart.refund ? c.voidInk : c.totalInk,
                  labelInk: c.muted,
                  valueSize: 28,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(flex: 10, child: StatTile(label: 'PAID', value: rs(cart.paidCents))),
              const SizedBox(width: 10),
              Expanded(
                flex: 10,
                child: StatTile(
                  label: 'CHANGE',
                  value: rs(cart.changeCents),
                  fill: done ? AppColors.success : null,
                  ink: done ? Colors.white : c.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
