import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/responsive/breakpoints.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../core/widgets/amount_display.dart';
import '../../../../../core/widgets/numeric_keypad.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../../../core/widgets/pos_dialog.dart';
import '../../domain/entities/payout_entry.dart';
import '../../domain/usecases/get_payout_reasons.dart';

/// Payout.dc.html. Pops a [PayoutEntry].
class PayoutScreen extends StatefulWidget {
  const PayoutScreen({super.key});

  @override
  State<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends State<PayoutScreen> {
  List<String>? _reasons;
  String? _error;
  int? _selected;
  String _amount = '';

  int get _cents => Money.toCents(double.tryParse(_amount) ?? 0);

  @override
  void initState() {
    super.initState();
    getIt<GetPayoutReasons>()().then((result) {
      if (!mounted) return;
      setState(() => switch (result) {
        Ok(:final value) => _reasons = value,
        Err(:final failure) => _error = failure.message,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final phone = Breakpoints.of(context) == DeviceClass.phone;
    final left = _left(context);
    final right = Column(
      children: [
        AmountDisplay(label: 'Amount', text: Money.lkr(Money.fromCents(_cents))),
        const SizedBox(height: 14),
        NumericKeypad(keyHeight: 60, onKey: (k) => setState(() => _amount = applyAmountKey(_amount, k, maxLength: 7))),
      ],
    );
    return PosDialog(
      title: 'Payout',
      subtitle: 'Cash paid out of the drawer',
      icon: Icons.outbox_outlined,
      iconColor: context.colors.holdInk,
      iconFill: context.colors.holdFill,
      width: 980,
      child: SingleChildScrollView(
        child: phone
            ? Column(children: [left, const SizedBox(height: 20), right])
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: left), const SizedBox(width: 24), SizedBox(width: 360, child: right)]),
      ),
    );
  }

  Widget _left(BuildContext context) {
    final c = context.colors;
    final reasons = _reasons;
    final ready = reasons != null && _selected != null && _cents > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Reason for payout:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.inkSecondary)),
        const SizedBox(height: 10),
        if (_error != null)
          Text(_error!, style: TextStyle(color: c.voidInk))
        else if (reasons == null)
          const Center(child: CircularProgressIndicator())
        else if (reasons.isEmpty)
          Text('No payout items yet.', style: TextStyle(color: c.muted))
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 4,
            children: [
              for (var i = 0; i < reasons.length; i++)
                Semantics(
                  inMutuallyExclusiveGroup: true,
                  checked: i == _selected,
                  child: Material(
                    color: i == _selected ? c.selection : c.inputFill,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: i == _selected ? c.primary : c.line, width: i == _selected ? 2 : 1),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => _selected = i),
                      child: Center(
                        child: Text(
                          reasons[i],
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: i == _selected ? c.primary : c.inkSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 10),
        Text('Payout items are set in Product Management › Manage Payout Products', style: TextStyle(fontSize: 12, color: c.muted)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: PosButton(label: 'Cancel', height: 58, style: PosButtonStyle.secondary, onPressed: () => context.pop())),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: PosButton(
                label: 'Add',
                height: 58,
                fontSize: 16,
                style: PosButtonStyle.primary,
                onPressed: ready ? () => context.pop(PayoutEntry(reasons[_selected!], _cents)) : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
