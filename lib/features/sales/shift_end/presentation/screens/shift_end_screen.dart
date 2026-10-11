import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/config/terminal_info.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/responsive/breakpoints.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/report_export.dart';
import '../../../../../core/widgets/shift_summary_sections.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../../../core/widgets/pos_dialog.dart';
import '../../../../../core/platform/report_output.dart';
import '../../../../../core/reports/shift_summary.dart';
import '../../../../../core/reports/shift_summary_document.dart';
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
                      child: ShiftSummarySections(summary: s, columns: columns),
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
                    label: 'Print',
                    icon: Icons.print_outlined,
                    height: 56,
                    fontSize: 16,
                    style: PosButtonStyle.secondary,
                    onPressed: s == null
                        ? null
                        : () => printReport(
                            context,
                            shiftSummaryDocument(s, terminal: terminal, shiftId: getIt<SessionHolder>().value?.logId),
                            getIt<ReportOutput>(),
                          ),
                  ),
                  const SizedBox(width: 10),
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

