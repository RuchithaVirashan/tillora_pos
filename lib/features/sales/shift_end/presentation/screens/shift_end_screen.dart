import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/config/terminal_info.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/responsive/breakpoints.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../../../core/widgets/pos_dialog.dart';
import '../../domain/entities/shift_summary.dart';
import '../../domain/usecases/end_shift.dart';

/// ShiftEnd.dc.html, step 2. Closes the shift on open; [onDone] signs out.
class ShiftEndScreen extends StatefulWidget {
  const ShiftEndScreen({super.key, required this.drawerFloatCents, required this.onDone});

  final int drawerFloatCents;
  final VoidCallback onDone;

  @override
  State<ShiftEndScreen> createState() => _ShiftEndScreenState();
}

class _ShiftEndScreenState extends State<ShiftEndScreen> {
  ShiftSummary? _summary;
  String? _error;

  @override
  void initState() {
    super.initState();
    getIt<EndShift>()(getIt<SessionHolder>().current, drawerFloatCents: widget.drawerFloatCents).then((result) {
      if (!mounted) return;
      setState(() => switch (result) {
        Ok(:final value) => _summary = value,
        Err(:final failure) => _error = failure.message,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = _summary;
    final time = DateFormat('HH:mm');
    final terminal = getIt<TerminalInfoHolder>().value.terminalName;
    final columns = switch (Breakpoints.of(context)) {
      DeviceClass.phone => 1,
      DeviceClass.tablet => 2,
      DeviceClass.desktop => 3,
    };

    return PopScope(
      canPop: false,
      child: PosDialog(
        title: 'Shift End Report',
        width: 1160,
        height: 800,
        headerDivider: true,
        onClose: widget.onDone,
        trailing: s == null ? null : const _CompletedPill(),
        child: Column(
          children: [
            if (s != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Step 2 of 2 · ${s.userName} · ${time.format(s.startedAt)} – ${time.format(s.endedAt)} · Terminal $terminal',
                    style: TextStyle(fontSize: 13, color: c.muted),
                  ),
                ),
              ),
            Expanded(
              child: _error != null
                  ? Center(child: Text(_error!, style: TextStyle(color: c.voidInk, fontWeight: FontWeight.w700)))
                  : s == null
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 16, 28, 22),
                      child: _Sections(summary: s, columns: columns),
                    ),
            ),
            Container(
              height: 88,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Sections shown are set in System Configuration › Shift Report Setting',
                      style: TextStyle(fontSize: 13, color: c.muted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PosButton(
                    label: 'OK',
                    height: 56,
                    fontSize: 16,
                    style: PosButtonStyle.success,
                    onPressed: s == null && _error == null ? null : widget.onDone,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedPill extends StatelessWidget {
  const _CompletedPill();

  @override
  Widget build(BuildContext context) => Container(
    height: 30,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(color: AppColors.successTint, borderRadius: BorderRadius.circular(999)),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 3.5, backgroundColor: AppColors.success),
        SizedBox(width: 6),
        Text('Processing Completed', style: TextStyle(color: AppColors.successInk, fontSize: 13, fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _Sections extends StatelessWidget {
  const _Sections({required this.summary, required this.columns});

  final ShiftSummary summary;
  final int columns;

  static String _rs(int cents) => Money.lkr(Money.fromCents(cents));

  static String _hour(int h) => '${h.toString().padLeft(2, '0')}:00';

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final sections = <(String, List<(String, String)>, int)>[
      (
        'CASH FLOW',
        [
          ('Drawer float', _rs(s.drawerFloatCents)),
          for (final e in s.salesByMethod.entries) ('${e.key} sales', _rs(e.value)),
          ('Refunds', _rs(s.refundsCents)),
          ('Cash lifts', _rs(s.cashLiftsCents)),
          ('Expected in drawer', _rs(s.expectedInDrawerCents)),
        ],
        1,
      ),
      (
        'DEPARTMENT',
        s.salesByDepartment.isEmpty ? [('No sales', '')] : [for (final e in s.salesByDepartment.entries) (e.key, _rs(e.value))],
        1,
      ),
      (
        'ACTIVITY',
        [
          ('Transactions', '${s.transactionCount}'),
          ('Total takings', _rs(s.totalCents)),
          ('No sales', '${s.noSaleCount}'),
          ('Void lines', '${s.voidLineCount}'),
          ('Void sales', '${s.voidSaleCount}'),
        ],
        1,
      ),
      (
        'HOURLY SALE',
        s.salesByHour.isEmpty
            ? [('No sales', '')]
            : [for (final e in s.salesByHour.entries) ('${_hour(e.key)} – ${_hour(e.key + 1)}', _rs(e.value))],
        columns > 1 ? 2 : 1,
      ),
    ];

    return LayoutBuilder(
      builder: (context, box) {
        const gap = 14.0;
        final unit = (box.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (title, rows, span) in sections)
              SizedBox(width: unit * span + gap * (span - 1), child: _SectionCard(title: title, rows: rows)),
          ],
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: c.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1, color: c.muted)),
          const SizedBox(height: 6),
          for (final (label, value) in rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.rowLine))),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: c.ink))),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
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
