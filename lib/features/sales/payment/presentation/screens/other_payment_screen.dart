import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/responsive/breakpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../core/widgets/amount_display.dart';
import '../../../../../core/widgets/numeric_keypad.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../../../core/widgets/pos_dialog.dart';
import '../../../cart/domain/entities/cart.dart';
import '../../domain/entities/payment_type.dart';
import '../../domain/usecases/get_payment_types.dart';

/// OtherPayment.dc.html. Pops a [Tender] for the chosen payment type.
class OtherPaymentScreen extends StatefulWidget {
  const OtherPaymentScreen({super.key, required this.cart});

  final Cart cart;

  @override
  State<OtherPaymentScreen> createState() => _OtherPaymentScreenState();
}

class _OtherPaymentScreenState extends State<OtherPaymentScreen> {
  List<PaymentType>? _types;
  String? _error;
  int _selected = 0;
  bool _partial = false;
  String _amount = '';

  int get _due => widget.cart.dueCents;

  /// Full payment always takes the exact balance; partial takes the typed
  /// amount, capped below the balance.
  /// Partial: the typed amount. Second payment: typed amount, else the
  /// balance. Otherwise the balance.
  int get _payCents {
    final typed = Money.toCents(double.tryParse(_amount) ?? 0);
    if (_partial) return typed;
    if (_secondPayment && typed > 0) return typed;
    return _due;
  }

  /// Cash given back when a second payment is more than the balance.
  int get _changeCents => _secondPayment && _payCents > _due ? _payCents - _due : 0;

  /// The sale already has its first payment.
  bool get _secondPayment => widget.cart.tenders.isNotEmpty;

  bool get _valid =>
      _types != null && _types!.isNotEmpty && _payCents > 0 && (_partial ? _payCents < _due : _payCents >= _due);

  @override
  void initState() {
    super.initState();
    getIt<GetPaymentTypes>()().then((result) {
      if (!mounted) return;
      setState(() => switch (result) {
        Ok(:final value) => _types = value,
        Err(:final failure) => _error = failure.message,
      });
    });
  }

  void _pay() {
    final type = _types![_selected];
    context.pop(Tender.other(type.name, type.id, _payCents));
  }

  @override
  Widget build(BuildContext context) {
    final phone = Breakpoints.of(context) == DeviceClass.phone;
    final left = _left(context);
    final right = _right(context);
    return PosDialog(
      title: 'Other Payment',
      width: 1100,
      height: phone ? null : 760,
      headerDivider: true,
      child: phone
          ? SingleChildScrollView(child: Column(children: [left, SizedBox(height: 520, child: right)]))
          : Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: left), SizedBox(width: 380, child: right)]),
    );
  }

  Widget _left(BuildContext context) {
    final c = context.colors;
    final cart = widget.cart;
    final types = _types;
    final name = types == null || types.isEmpty ? '' : types[_selected].name;
    final amount = Money.lkr(Money.fromCents(_payCents));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: StatTile(label: 'Total', value: _rs(cart.totalCents.abs()), valueSize: 24)),
              const SizedBox(width: 12),
              Expanded(child: StatTile(label: 'Paid', value: _rs(cart.paidCents), valueSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(label: 'Balance', value: _rs(_due), valueSize: 24, fill: c.primary, ink: Colors.white, labelInk: const Color(0xFFC7D4E6)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Payment types from Payment Type Manager', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.muted)),
          const SizedBox(height: 10),
          if (_error != null)
            Text(_error!, style: TextStyle(color: c.voidInk))
          else if (types == null)
            const Center(child: CircularProgressIndicator())
          else if (types.isEmpty)
            Text('No payment types are enabled. Turn them on in Back Office › Payment Types.', style: TextStyle(color: c.muted))
          else
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: [for (var i = 0; i < types.length; i++) _typeTile(c, types[i], i == _selected, () => setState(() => _selected = i))],
            ),
          const SizedBox(height: 20),
          Material(
            color: c.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: c.line)),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              value: _partial,
              activeTrackColor: AppColors.success,
              // Only the first of the two payments can be partial.
              onChanged: _secondPayment
                  ? null
                  : (v) => setState(() {
                      _partial = v;
                      _amount = '';
                    }),
              title: Text('Partial Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.ink)),
              subtitle: Text(
                _secondPayment
                    ? 'Already part paid — this payment completes the sale. Type more than the balance to give change.'
                    : 'Pay part of the balance with this type',
                style: TextStyle(fontSize: 14, color: c.muted),
              ),
            ),
          ),
          const Spacer(),
          if (name.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(color: context.colors.holdFill, borderRadius: BorderRadius.circular(16)),
              child: Text(
                _partial && _payCents >= _due
                    ? 'A partial payment must be less than the balance.'
                    : _partial
                    ? 'Are you sure you want to complete the partial payment $amount in $name?'
                    : _secondPayment && _payCents < _due
                    ? 'This payment must be at least the balance of ${Money.lkr(Money.fromCents(_due))}.'
                    : _changeCents > 0
                    ? 'Are you sure you want to pay with $amount in $name? Give ${Money.lkr(Money.fromCents(_changeCents))} change in cash.'
                    : 'Are you sure you want to pay with $amount in $name?',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.colors.holdInk),
              ),
            ),
        ],
      ),
    );
  }

  Widget _right(BuildContext context) {
    final c = context.colors;
    final types = _types;
    final name = types == null || types.isEmpty ? '' : types[_selected].name;
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(color: c.surfaceMuted, border: Border(left: BorderSide(color: c.line))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AmountDisplay(label: 'Amount', text: Money.lkr(Money.fromCents(_payCents))),
          const SizedBox(height: 14),
          Expanded(
            child: IgnorePointer(
              ignoring: !_partial && !_secondPayment,
              child: Opacity(
                opacity: _partial || _secondPayment ? 1 : 0.45,
                child: LayoutBuilder(
                  builder: (context, box) => NumericKeypad(
                    withDot: true,
                    keyHeight: ((box.maxHeight - 24) / 4).clamp(44, 80),
                    onKey: (k) => setState(() => _amount = applyAmountKey(_amount, k)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          PosButton(
            label: name.isEmpty ? 'Pay' : (_partial ? 'Partial payment with $name' : 'Pay with $name'),
            height: 64,
            fontSize: 17,
            radius: 16,
            style: PosButtonStyle.success,
            onPressed: _valid ? _pay : null,
          ),
        ],
      ),
    );
  }

  static String _rs(int cents) => Money.lkr(Money.fromCents(cents));

  Widget _typeTile(AppColors c, PaymentType t, bool on, VoidCallback onTap) => Material(
    color: c.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: on ? c.primary : c.line, width: on ? 2 : 1),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payments_outlined, color: on ? c.primary : c.muted),
          const SizedBox(width: 10),
          Flexible(child: Text(t.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.ink))),
        ],
      ),
    ),
  );
}
