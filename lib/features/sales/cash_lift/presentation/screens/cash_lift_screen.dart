import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../core/widgets/amount_display.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/numeric_keypad.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../../../core/widgets/pos_dialog.dart';
import '../../domain/usecases/lift_cash.dart';

/// CashLift.dc.html. Pops `true` once the lift is recorded.
class CashLiftScreen extends StatefulWidget {
  const CashLiftScreen({super.key});

  @override
  State<CashLiftScreen> createState() => _CashLiftScreenState();
}

class _CashLiftScreenState extends State<CashLiftScreen> {
  String _amount = '';
  bool _busy = false;

  int get _cents => Money.toCents(double.tryParse(_amount) ?? 0);

  Future<void> _lift() async {
    setState(() => _busy = true);
    final result = await getIt<LiftCash>()(getIt<SessionHolder>().current, _cents);
    if (!mounted) return;
    if (result case Err(:final failure)) {
      setState(() => _busy = false);
      return showToast(context, failure.message, error: true);
    }
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Money.lkr(Money.fromCents(_cents));
    return PosDialog(
      title: 'Cash Lift',
      icon: Icons.savings_outlined,
      iconColor: const Color(0xFF0B7A55),
      iconFill: AppColors.successTint,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AmountDisplay(label: 'Cash Lift Amount', text: text),
            const SizedBox(height: 16),
            NumericKeypad(onKey: (k) => setState(() => _amount = applyAmountKey(_amount, k, maxLength: 8))),
            const SizedBox(height: 16),
            if (_cents > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(color: AppColors.warningTint, borderRadius: BorderRadius.circular(16)),
                child: Text(
                  'Are you sure you want to lift $text from cash?',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.warningInk),
                ),
              )
            else
              Text('Enter the amount moving to the safe.', style: TextStyle(color: c.muted)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PosButton(label: 'Reset', height: 58, fontSize: 16, style: PosButtonStyle.secondary, onPressed: () => setState(() => _amount = '')),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: PosButton(label: 'OK', height: 58, fontSize: 16, style: PosButtonStyle.primary, onPressed: _cents > 0 && !_busy ? _lift : null),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
