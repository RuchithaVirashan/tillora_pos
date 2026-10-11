import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../core/widgets/amount_display.dart';
import '../../../../../core/widgets/numeric_keypad.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../../../core/widgets/pos_dialog.dart';

/// DrawerFloat.dc.html, step 1 of ending a shift. Pops the float in cents.
class DrawerFloatScreen extends StatefulWidget {
  const DrawerFloatScreen({super.key});

  @override
  State<DrawerFloatScreen> createState() => _DrawerFloatScreenState();
}

class _DrawerFloatScreenState extends State<DrawerFloatScreen> {
  String _amount = '';

  int get _cents => Money.toCents(double.tryParse(_amount) ?? 0);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PosDialog(
      title: 'Drawer Float',
      subtitle: 'Step 1 of 2 · End shift',
      icon: Icons.power_settings_new_rounded,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Enter the float you are leaving in the drawer for the next shift.',
                style: TextStyle(fontSize: 14, color: c.inkSecondary)),
            const SizedBox(height: 16),
            AmountDisplay(label: 'Drawer Float Amount', text: Money.lkr(Money.fromCents(_cents))),
            const SizedBox(height: 16),
            NumericKeypad(onKey: (k) => setState(() => _amount = applyAmountKey(_amount, k, maxLength: 8))),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PosButton(
                    label: 'Reset',
                    height: 58,
                    fontSize: 16,
                    style: PosButtonStyle.secondary,
                    onPressed: () => setState(() => _amount = ''),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: PosButton(label: 'OK', height: 58, fontSize: 16, style: PosButtonStyle.primary, onPressed: () => context.pop(_cents)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
