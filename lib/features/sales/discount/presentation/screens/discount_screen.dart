import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/responsive/breakpoints.dart';
import '../../../../../core/session/access_rights.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../core/widgets/numeric_keypad.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../../../core/widgets/pos_dialog.dart';
import '../../../cart/domain/entities/cart.dart';
import '../../domain/entities/discount_choice.dart';

/// Discount.dc.html. Pops a [DiscountChoice].
class DiscountScreen extends StatefulWidget {
  const DiscountScreen({super.key, required this.cart, this.wholeSale = false});

  final Cart cart;
  final bool wholeSale;

  @override
  State<DiscountScreen> createState() => _DiscountScreenState();
}

class _DiscountScreenState extends State<DiscountScreen> {
  final _access = getIt<SessionHolder>().current.access;
  late bool _wholeSale = widget.wholeSale || widget.cart.selectedLine == null;
  String _percent = '';

  int get _value => (int.tryParse(_percent) ?? 0).clamp(0, 100);

  bool get _allowed => _access.can(_wholeSale ? AccessRights.saleDiscount : AccessRights.productDiscount);

  int get _baseCents => _wholeSale ? widget.cart.saleBaseCents : (widget.cart.selectedLine?.amountCents ?? 0);

  void _key(String k) => setState(() {
    if (k == PadKey.delete) {
      if (_percent.isNotEmpty) _percent = _percent.substring(0, _percent.length - 1);
    } else if (k != PadKey.dot && _percent.length < 3) {
      _percent += k;
    }
  });

  @override
  Widget build(BuildContext context) {
    final phone = Breakpoints.of(context) == DeviceClass.phone;
    final left = _left(context);
    final right = _right();
    return PosDialog(
      title: 'Discount',
      width: 900,
      trailing: _Tabs(wholeSale: _wholeSale, canItem: widget.cart.selectedLine != null, onChanged: (v) => setState(() => _wholeSale = v)),
      child: SingleChildScrollView(
        child: phone
            ? Column(children: [left, const SizedBox(height: 20), right])
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: left), const SizedBox(width: 24), SizedBox(width: 340, child: right)]),
      ),
    );
  }

  Widget _left(BuildContext context) {
    final c = context.colors;
    final line = widget.cart.selectedLine;
    final off = (_baseCents * _value / 100).round();
    String rs(int cents) => Money.lkr(Money.fromCents(cents));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _wholeSale ? 'Whole sale' : '${line!.item.description} × ${line.quantity}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.ink),
                    ),
                    Text(
                      _wholeSale ? '${widget.cart.itemCount} items (Sale%)' : 'Selected line (Prod%)',
                      style: TextStyle(fontSize: 13, color: c.muted),
                    ),
                  ],
                ),
              ),
              Text(rs(_baseCents), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.ink)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _figure(c, 'Discount Value', '$_value%')),
            const SizedBox(width: 12),
            Expanded(child: _figure(c, 'Amount', '−${rs(off)}')),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              const Expanded(child: Text('New price', style: TextStyle(color: Color(0xFFC7D4E6), fontWeight: FontWeight.w700))),
              Text(rs(_baseCents - off), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
        ),
        if (!_allowed) ...[
          const SizedBox(height: 12),
          Text(
            'You do not have ${_wholeSale ? 'sale' : 'product'} discount access.',
            style: TextStyle(color: c.voidInk, fontWeight: FontWeight.w700),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: PosButton(label: 'Reset', height: 58, fontSize: 16, style: PosButtonStyle.secondary, onPressed: () => setState(() => _percent = '')),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: PosButton(
                label: 'Apply discount',
                height: 58,
                fontSize: 16,
                style: PosButtonStyle.primary,
                onPressed: _allowed && _value > 0 ? () => context.pop(DiscountChoice(percent: _value, wholeSale: _wholeSale)) : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _right() {
    return Column(
      children: [
        Row(
          children: [
            for (final (i, p) in const [5, 10, 15, 20].indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: PosButton(label: '$p%', height: 48, style: PosButtonStyle.holdTint, onPressed: () => setState(() => _percent = '$p')),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        NumericKeypad(withDot: true, keyHeight: 60, onKey: _key),
      ],
    );
  }

  Widget _figure(AppColors c, String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    decoration: BoxDecoration(border: Border.all(color: c.line), borderRadius: BorderRadius.circular(16)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.muted)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: c.ink)),
      ],
    ),
  );
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.wholeSale, required this.canItem, required this.onChanged});

  final bool wholeSale;
  final bool canItem;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget tab(bool value, String label) {
      final on = value == wholeSale;
      final enabled = value || canItem;
      return Semantics(
        selected: on,
        button: true,
        child: Material(
          color: on ? c.surface : Colors.transparent,
          elevation: on ? 1 : 0,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: enabled ? () => onChanged(value) : null,
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: on ? c.primary : (enabled ? c.inkSecondary : c.line)),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.background, borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [tab(false, 'Discount For Item'), const SizedBox(width: 4), tab(true, 'Discount For Sale')]),
    );
  }
}
