import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../app/router/routes.dart';
import '../../../../../core/config/terminal_info.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/platform/customer_display.dart';
import '../../../../../core/platform/system_tools.dart';
import '../../../../../core/responsive/breakpoints.dart';
import '../../../../../core/session/training_mode.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/pos_dialog.dart';
import '../../domain/usecases/set_auto_print.dart';
import '../widgets/reset_void_dialog.dart';

/// MoreFunctions.dc.html.
class MoreFunctionsScreen extends StatefulWidget {
  const MoreFunctionsScreen({super.key, this.saleInProgress = false});

  /// Training Mode only switches between sales, so a real sale is never
  /// left unsaved and a practice one never saved.
  final bool saleInProgress;

  @override
  State<MoreFunctionsScreen> createState() => _MoreFunctionsScreenState();
}

class _MoreFunctionsScreenState extends State<MoreFunctionsScreen> {
  bool _autoPrint = getIt<TerminalInfoHolder>().value.autoPrint;
  bool _display = getIt<CustomerDisplay>().isOpen;
  final _displaySupported = getIt<CustomerDisplay>().isSupported;
  final _training = getIt<TrainingMode>();

  Future<void> _toggleTraining() async {
    if (widget.saleInProgress) return showToast(context, 'Finish or void the current sale first', error: true);
    final on = !_training.value;
    final ok = await confirm(
      context,
      title: on ? 'Start Training Mode?' : 'Leave Training Mode?',
      message: on
          ? 'Sales will not be saved, stock and the drawer are left alone, and No Sale, Cash Lift and Hold are off.'
          : 'Sales are saved again from the next one.',
      confirmLabel: on ? 'Start' : 'Leave',
    );
    if (!ok || !mounted) return;
    setState(() => _training.value = on);
    showToast(context, on ? 'Training Mode on' : 'Training Mode off');
  }

  Future<void> _toggleDisplay() async {
    if (!_displaySupported) return showToast(context, 'No customer display on this device', error: true);
    final next = !_display;
    final result = await getIt<SetCustomerDisplay>()(next);
    if (!mounted) return;
    if (result case Err(:final failure)) return showToast(context, failure.message, error: true);
    setState(() => _display = next);
  }

  Future<void> _toggleAutoPrint() async {
    final next = !_autoPrint;
    final result = await getIt<SetAutoPrint>()(next);
    if (!mounted) return;
    if (result case Err(:final failure)) return showToast(context, failure.message, error: true);
    setState(() => _autoPrint = next);
  }

  Future<void> _calculator() async {
    if (!await getIt<SystemTools>().openCalculator() && mounted) {
      showToast(context, 'No calculator on this device', error: true);
    }
  }

  void _notPorted(String name) => showToast(context, '$name is not ported yet');

  Future<void> _cashLift() async {
    final lifted = await context.push<bool>(Routes.cashLift);
    if (lifted == true && mounted) {
      showToast(context, 'Cash lift recorded');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final columns = switch (Breakpoints.of(context)) {
      DeviceClass.phone => 2,
      _ => 3,
    };
    final tiles = [
      _Fn('Cash Lift', 'Move cash to the safe', Icons.savings_outlined, const Color(0xFF0B7A55), const Color(0xFFE3F5EE), _cashLift),
      _Fn('Open Calculator', 'Opens the system calculator', Icons.calculate_outlined, const Color(0xFF3B4A60), const Color(0xFFEEF1F5), _calculator),
      _Fn('Auto Print', _autoPrint ? 'On · print after every sale' : 'Off', Icons.print_outlined, const Color(0xFF2952A3), const Color(0xFFE8EEFB),
          _toggleAutoPrint, on: _autoPrint),
      _Fn('Currency Converter', 'Not ported yet', Icons.currency_exchange_rounded, const Color(0xFF9A5B00), const Color(0xFFFFF3DC),
          () => _notPorted('Currency Converter')),
      _Fn('Reset Void Counts', 'Admin approves a fresh count', Icons.restart_alt_rounded, const Color(0xFFB4233C), const Color(0xFFFDECEE),
          () => showDialog<bool>(context: context, builder: (_) => const ResetVoidDialog())),
      _Fn('Training Mode', _training.value ? 'On · practice sales are not saved' : 'Off', Icons.school_outlined, const Color(0xFF5B3FB0), const Color(0xFFEFEAFB),
          _toggleTraining, on: _training.value),
      _Fn(
        'Customer Display',
        !_displaySupported ? 'Not available on this device' : (_display ? 'On · second screen showing' : 'Off'),
        Icons.connected_tv_outlined,
        const Color(0xFF0B6E6E),
        const Color(0xFFDFF3F3),
        _toggleDisplay,
        on: _display,
      ),
    ];

    return PosDialog(
      title: 'More Functions',
      width: 900,
      child: GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.45,
        children: [for (final t in tiles) _FnTile(t)],
      ),
    );
  }
}

class _Fn {
  const _Fn(this.name, this.description, this.icon, this.ink, this.fill, this.onTap, {this.on = false});

  final String name;
  final String description;
  final IconData icon;
  final Color ink;
  final Color fill;
  final VoidCallback onTap;
  final bool on;
}

class _FnTile extends StatelessWidget {
  const _FnTile(this.fn);

  final _Fn fn;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      toggled: fn.name == 'Auto Print' || fn.name == 'Customer Display' || fn.name == 'Training Mode' ? fn.on : null,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: fn.on ? fn.ink : c.line, width: fn.on ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: fn.onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: fn.fill, borderRadius: BorderRadius.circular(16)),
                  child: Icon(fn.icon, color: fn.ink, size: 26),
                ),
                const Spacer(),
                Text(fn.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.ink)),
                const SizedBox(height: 4),
                Text(
                  fn.description,
                  style: TextStyle(fontSize: 13, fontWeight: fn.on ? FontWeight.w800 : FontWeight.w500, color: fn.on ? fn.ink : c.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
